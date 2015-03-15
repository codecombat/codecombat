#! /usr/bin/env python
#
# Mixpanel, Inc. -- http://mixpanel.com/
#
# Python API client library to consume mixpanel.com analytics data.
#
# Copyright 2010-2013 Mixpanel, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import hashlib
import urllib
import urllib2
import time
try:
    import json
except ImportError:
    import simplejson as json

class Mixpanel(object):

    # https right?
    ENDPOINT = 'http://mixpanel.com/api'
    DATA_ENDPOINT = 'http://data.mixpanel.com/api'
    VERSION = '2.0'

    def __init__(self, api_key, api_secret):
        self.api_key = api_key
        self.api_secret = api_secret

    def request(self, methods, params, format='json'):
        """
            methods - List of methods to be joined, e.g. ['events', 'properties', 'values']
                      will give us http://mixpanel.com/api/2.0/events/properties/values/
            params - Extra parameters associated with method
        """
        params['api_key'] = self.api_key
        params['expire'] = int(time.time()) + 600   # Grant this request 10 minutes.
        params['format'] = format
        
        if 'sig' in params: del params['sig']
        params['sig'] = self.hash_args(params)

        if 'export' in methods:
            request_url = '/'.join([self.DATA_ENDPOINT, str(self.VERSION)] + methods) + '/?' + self.unicode_urlencode(params)
        else:
            request_url = '/'.join([self.ENDPOINT, str(self.VERSION)] + methods) + '/?' + self.unicode_urlencode(params)
        request = urllib2.urlopen(request_url, timeout=120)
        data = request.read()
        # return json.loads(data)
        return data

    def unicode_urlencode(self, params):
        """
            Convert lists to JSON encoded strings, and correctly handle any
            unicode URL parameters.
        """
        if isinstance(params, dict):
            params = params.items()
        for i, param in enumerate(params):
            if isinstance(param[1], list):
                params[i] = (param[0], json.dumps(param[1]),)

        return urllib.urlencode(
            [(k, isinstance(v, unicode) and v.encode('utf-8') or v) for k, v in params]
        )

    def hash_args(self, args, secret=None):
        """
            Hashes arguments by joining key=value pairs, appending a secret, and
            then taking the MD5 hex digest.
        """
        for a in args:
            if isinstance(args[a], list): args[a] = json.dumps(args[a])

        args_joined = ''
        for a in sorted(args.keys()):
            if isinstance(a, unicode):
                args_joined += a.encode('utf-8')
            else:
                args_joined += str(a)

            args_joined += '='

            if isinstance(args[a], unicode):
                args_joined += args[a].encode('utf-8')
            else:
                args_joined += str(args[a])

        hash = hashlib.md5(args_joined)

        if secret:
            hash.update(secret)
        elif self.api_secret:
            hash.update(self.api_secret)
        return hash.hexdigest()

if __name__ == '__main__':
    api = Mixpanel(
        api_key = 'YOUR_API_KEY',
        api_secret = 'YOUR_API_SECRET'
    )
    # data = api.request(['events'], {
    #     'event' : ['Finished subscription purchase',],
    #     'unit' : 'hour',
    #     'interval' : 24,
    #     'type': 'general'
    # })
    
    # data = api.request(['funnels', 'list'], {})
    
    data = api.request(['export'], {
        'event' : ['Finished subscription purchase',],
        'from_date' : '2014-14-05',
        'to_date' : '2014-14-06'
    })
    for line in data.split('\n'):
        try:
            if len(line):
                event = json.loads(line)
                print event['event'], event['properties']['distinct_id']
        except:
            print 'error'
            print line

