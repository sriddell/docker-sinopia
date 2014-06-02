#Overview
Dockerfile and configuration for sinopia.
Will install node from source in a 14.04 ubuntu image, then install and configure sinopia to run.

The /storage and /config directories are externalized.  Place the config.yaml in the directory mapped to /config.

#Example sinopia config for a private repo with no upstream.

```
# path to a directory with all packages
storage: /storage

# a list of users
users:
  admin:
    # crypto.createHash('sha1').update(pass).digest('hex')
    password: 631edf78896d6ef3fb8f3ad297242c0728fb4694

# a list of other known repositories we can talk to
#uplinks:
#  npmjs:
#    url: https://registry.npmjs.org/

    # amount of time to wait for repository to respond
    # before giving up and use the local cached copy
#    timeout: 30s

    # maximum time in which data is considered up to date
    #
    # default is 2 minutes, so server won't request the same data from
    # uplink if a similar request was made less than 2 minutes ago
#    maxage: 2m

    # if two subsequent requests fail, no further requests will be sent to
    # this uplink for five minutes
    #max_fails: 2
    #fail_timeout: 5m

    # timeouts are defined in the same way as nginx, see:
    # http://wiki.nginx.org/ConfigNotation

packages:
  # uncomment this for packages with "local-" prefix to be available
  # for admin only, it's a recommended way of handling private packages
  #'local-*':
  #  allow_access: all
  #  allow_publish: admin
  #  # you can override storage directory for a group of packages this way:
  #  storage: './private_storage'

  '*':
    # allow all users to read packages ('all' is a keyword)
    # this includes non-authenticated users
    allow_access: all

    # allow 'admin' to publish packages
    allow_publish: admin

    # if package is not available locally, proxy requests to 'npmjs' registry
#    proxy: npmjs


#####################################################################
# Advanced settings
#####################################################################

# if you use nginx with custom path, use this to override links
#url_prefix: https://dev.company.local/sinopia/

# you can specify listen address (or simply a port)
listen: 0.0.0.0:4873

# type: file | stdout | stderr
# level: trace | debug | info | http (default) | warn | error | fatal
#
# parameters for file: name is filename
#  {type: 'file', path: 'sinopia.log', level: 'debug'},
#
# parameters for stdout and stderr: format: json | pretty
#  {type: 'stdout', format: 'pretty', level: 'debug'},
logs:
  - {type: stdout, format: pretty, level: http}
  #- {type: file, path: sinopia.log, level: info}

# you can specify proxy used with all requests in wget-like manner here
# (or set up ENV variables with the same name)
#http_proxy: http://something.local/
#https_proxy: https://something.local/
#no_proxy: localhost,127.0.0.1

# maximum size of uploaded json document
# increase it if you have "request entity too large" errors
#max_body_size: 1mb

# Workaround for countless npm bugs. Must have for npm <1.14.x, but expect
# it to be turned off in future versions. If `true`, latest tag is ignored,
# and the highest semver is placed instead.
#ignore_latest_tag: false
```

#Example sinopia config for a lazy-cashing instance with an npmjs.org upstream

```
# path to a directory with all packages
storage: /storage

# a list of users
users:
  admin:
    # crypto.createHash('sha1').update(pass).digest('hex')
    password: e38ad214943daad1d64c102faec29de4afe9da3d

# a list of other known repositories we can talk to
uplinks:
  npmjs:
    url: https://registry.npmjs.org/

    # amount of time to wait for repository to respond
    # before giving up and use the local cached copy
    timeout: 30s

    # maximum time in which data is considered up to date
    #
    # default is 2 minutes, so server won't request the same data from
    # uplink if a similar request was made less than 2 minutes ago
    maxage: 2m

    # if two subsequent requests fail, no further requests will be sent to
    # this uplink for five minutes
    #max_fails: 2
    #fail_timeout: 5m

    # timeouts are defined in the same way as nginx, see:
    # http://wiki.nginx.org/ConfigNotation

packages:
  # uncomment this for packages with "local-" prefix to be available
  # for admin only, it's a recommended way of handling private packages
  #'local-*':
  #  allow_access: all
  #  allow_publish: admin
  #  # you can override storage directory for a group of packages this way:
  #  storage: './private_storage'

  '*':
    # allow all users to read packages ('all' is a keyword)
    # this includes non-authenticated users
    allow_access: all

    # allow 'admin' to publish packages
    #allow_publish: admin

    # if package is not available locally, proxy requests to 'npmjs' registry
    proxy: npmjs


#####################################################################
# Advanced settings
#####################################################################

# if you use nginx with custom path, use this to override links
#url_prefix: https://dev.company.local/sinopia/

# you can specify listen address (or simply a port)
listen: 0.0.0.0:4873

# type: file | stdout | stderr
# level: trace | debug | info | http (default) | warn | error | fatal
#
# parameters for file: name is filename
#  {type: 'file', path: 'sinopia.log', level: 'debug'},
#
# parameters for stdout and stderr: format: json | pretty
#  {type: 'stdout', format: 'pretty', level: 'debug'},
logs:
  - {type: stdout, format: pretty, level: http}
  #- {type: file, path: sinopia.log, level: info}

# you can specify proxy used with all requests in wget-like manner here
# (or set up ENV variables with the same name)
#http_proxy: http://something.local/
#https_proxy: https://something.local/
#no_proxy: localhost,127.0.0.1

# maximum size of uploaded json document
# increase it if you have "request entity too large" errors
#max_body_size: 1mb

# Workaround for countless npm bugs. Must have for npm <1.14.x, but expect
# it to be turned off in future versions. If `true`, latest tag is ignored,
# and the highest semver is placed instead.
#ignore_latest_tag: false
```

#nginx configuration

npm does not yet support package resolution via multiple repositories, but you can setup similar behavior for a single private repo and npmjs.org or a caching sinopia instance with nginx.

Assuming a private sinopia instance on localhost:4873 with no upstream, and a caching instance on localhost:4874 with npmjs.org as the upstream (as in the above examples), the following nginx config will cause packages to be resolved from the private instance first, then the (public) lazy caching instance.

Note that I don't know how to make this work for more than two servers (e.g., if you want to define npmsjs.org as a fallback in nginx), as it's not clear how (if it's possible) to make nginx try servers in the same sequence every time.


```
upstream npmjsorg-servers {
    server localhost:4873;
    server localhost:4874      backup;
}

server {
    listen                  80;
    server_name             localhost;

    # Need big files
    client_max_body_size    1024m;

    # SSL Settings
    #include                 ssl/default_settings;

    location / {
        # OK to pass all, because all servers are local
        proxy_pass          http://npmjsorg-servers;

        # Proxy Settings
        proxy_redirect off;
        proxy_next_upstream error timeout invalid_header http_404 http_500 http_502 http_503 http_504;

        ### Set headers ###
        proxy_set_header    Accept-Encoding     "";
        proxy_set_header    X-Real-IP           $remote_addr;
        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto   $scheme;
        add_header          Front-End-Https     on;
        proxy_set_header    Host            172.16.158.30;
    }
}

server {
    listen                  81;
    server_name             localhost;

    client_max_body_size    1024m;

    location / {
        # Use backup on GET, not on PUT POST DELETE
        limit_except        PUT POST DELETE {
            proxy_pass      https://localhost:4874;
        }

        # Proxy Settings
        proxy_redirect off;

        ### Set headers ###
        proxy_set_header    Accept-Encoding     "";
        proxy_set_header    X-Real-IP           $remote_addr;
        proxy_set_header    X-Forwarded-For     $proxy_add_x_forwarded_for;
        proxy_set_header    X-Forwarded-Proto   $scheme;
        add_header          Front-End-Https     on;
        proxy_set_header    Host            registry.npmjs.org;
        proxy_set_header    Authorization   "";
    }
}
```
