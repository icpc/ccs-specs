#!/usr/bin/env php
<?php
/**
 * This is a helper script to check-api to verify that the contents of
 * the REST endpoints and the event feed are consistent. It is not
 * meant to be executed independently.
 */

$dir = $argv[1];

$endpoints = array_splice($argv, 2);

$feed_json = json_decode(file_get_contents($dir.'/event-feed.json'), true);

$debug = getenv('DEBUG');

$errors = 0;
$warnings = 0;

function error($msg)
{
    global $errors;

    $errors++;
    echo "Error: $msg\n";
}

function warning($msg)
{
    global $warnings;

    $warnings++;
    echo "Warning: $msg\n";
}

foreach ($feed_json as $row) {
    $endpoint = $row['type'];
    $id = isset($row['data']['id']) ? $row['data']['id'] : '_single_';
    $feed_data[$endpoint][$id][] = $row;
}

// Given two associative arrays, return the keys of their symmetric difference.
function array_diff_keys($a, $b)
{
    $keys = array_unique(array_merge(array_keys($a), array_keys($b)));
    $diff = [];
    foreach ($keys as $key) {
        if ((array_key_exists($key, $a) xor array_key_exists($key, $b)) ||
            (array_key_exists($key, $a) and ($a[$key]!==$b[$key]))) {
            $diff[] = $key;
        }
    }
    return $diff;
}

// Let's assume and check that each element ID gets created and deleted at most once.
foreach ($feed_data as $endpoint => $elements) {
    if ($endpoint==='state') {
        foreach ($elements as $id => $rows) {
            if ($id!=='_single_') {
                error("'state' cannot have ID '$id' set.");
            }
            for ($i=0; $i<count($rows); $i++) {
                if ($rows[$i]['op']!=='update') {
                    error("'state' operation '$rows[$i][op]' not allowed.");
                }
            }
        }
    } else {
        foreach ($elements as $id => $rows) {
            if ($rows[0]['op']!=='create') {
                error("'$endpoint/$id' not created first.");
            }
            for ($i=1; $i<count($rows); $i++) {
                switch ($rows[$i]['op']) {
                case 'create':
                    warning("'$endpoint/$id' created again.");
                    break;
                case 'update':
                    break;
                case 'delete':
                    if ($i<count($rows)-1) {
                        error("'$endpoint/$id' deleted before last change.");
                    }
                    break;
                default:
                    error("'$endpoint/$id' unknown operation '$rows[$i][op]'.");
                }
            }
        }
    }
}

// Now check that each REST endpoint element appears in the feed.
foreach ($endpoints as $endpoint) {
    $endpoint_json = json_decode(file_get_contents($dir.'/'.$endpoint.'.json'), true);
    if (in_array($endpoint,['contests','state'])) $endpoint_json = [$endpoint_json];
    foreach ($endpoint_json as $element) {
        $id = isset($element['id']) ? $element['id'] : '_single_';
        $endpoint_data[$endpoint][$id] = $element;
        if (!isset($feed_data[$endpoint][$id])) {
            error("'$endpoint".($id==='_single_' ? '' : "/$id")."' not found in feed.");
            if ($debug) var_dump($element);
        }
    }
}

// Finally check that each non-deleted item from the feed exists in
// its REST endpoint and has equal contents to its last feed entry.
foreach ($feed_data as $endpoint => $elements) {
    foreach ($elements as $id => $rows) {
        $last = end($rows);
        if ($last['op']!=='delete') {
            if (!isset($endpoint_data[$endpoint][$id])) {
                error("'$endpoint".($id==='_single_' ? '' : "/$id")."' not found in REST endpoint.");
            } elseif ($last['data']!==$endpoint_data[$endpoint][$id]) {
                $diff = array_diff_keys($last['data'], $endpoint_data[$endpoint][$id]);
                warning("'$endpoint".($id==='_single_' ? '' : "/$id")."' data mismatch between feed and REST endpoint: ".implode(',', $diff));
                if ($debug) var_dump($last['data'], $endpoint_data[$endpoint][$id]);
            }
        }
    }
}

if ($errors>0) {
    echo "Found $errors errors and $warnings warnings.\n";
    exit(1);
}

if ($warnings>0) {
    echo "Found $warnings warnings.\n";
}
