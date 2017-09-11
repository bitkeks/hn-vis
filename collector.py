#!/usr/bin/env python3.6

# collector.py to be used for collecting snapshots of the Hacker News frontpage
# Copyright 2017 Dominik Pataky <dom@netdecorator.org>
# Licensed under the GPLv3 license, see LICENSE

from bs4 import BeautifulSoup
import json
import requests as req
import re
import codecs
import os
from pprint import pprint
import time

cache_file = 'cached.txt'
now = int(time.time())
snaps_folder = './snaps/'
snap_file = os.path.join(snaps_folder, f'{now}.json')

url = 'https://news.ycombinator.com'
headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:50.0) Gecko/20100101 Firefox/50.0'}


# Fetch URL contents
try:
    r = req.get(url, headers=headers, allow_redirects=True)
except req.exceptions.ConnectionError as ex:
    exit(f"Error fetching URL {url}")


# Create snaps folder if necessary
if not os.path.exists(snaps_folder):
    os.mkdir(snaps_folder)


# Parse and process fetched data
soup = BeautifulSoup(r.text, 'lxml')
headlines = soup.find_all('tr', 'athing')


# Results JSON with metadata
results = {
    'timestamp': now,
    'request_time': r.elapsed.total_seconds(),
    'headlines': []
}

for hl in headlines:
    el_title = hl.select("td.title > a.storylink")[0]
    title = el_title.string

    el_rank = hl.select("td > span.rank")[0]
    rank = int(el_rank.string[:-1])  # cut dot

    el_info = hl.next_sibling

    subtext = el_info.get_text()
    if not any(['points by' in subtext, 'comments' in subtext]):
        # Advertisment/hiring shitpost
        continue

    el_score = el_info.select("td.subtext > span.score")[0]
    score = int(el_score.string[:-len(" points")])

    el_submitter = el_info.select("td.subtext > a.hnuser")[0]
    submitter = el_submitter.string

    el_age = el_info.select("td.subtext > span.age > a")[0]
    age = el_age.string

    el_commentcount = el_info.select("td.subtext > a")[-1]  # get last child

    commentcount = 0  # 'discuss'
    if el_commentcount.string != 'discuss':
        suffix = " comments"  # 'x comments'
        if not el_commentcount.string[-1] == 's':
            suffix = " comment"  # '1 comment'
        commentcount = int(el_commentcount.string[:-len(suffix)])

    headline_id = int(hl['id'])
    results['headlines'].append({
        'id': headline_id,
        'title': title,
        'rank': rank,
        'score': score,
        'commentcount': commentcount,
        'age': age
    })

with codecs.open(snap_file, 'w', 'utf8') as fh:
    json.dump(results, fh)

print("Fetched {} results in {} seconds, timestamp {}".format(
    len(results['headlines']),
    results['request_time'],
    now
))
