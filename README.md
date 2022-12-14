# reproduction of lua script + decompressor

We want to use lua scripts to edit the html of upstream responses. We noticed that brotli and gzip responses are not decoded in the filter chain, so we need to use a decompressor. We noticed that the decompressor doesn't provide the content to the lua filter from `body()`.

## tech

* envoy as a reverse proxy
    * [lua](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/lua_filter) for rewriting html
* [caddy](https://caddyserver.com/v2) used as a gzip file server
* docker

## how to

```
docker compose up --build
```

If the lua is working and replacement was successful, then you should see `<!-- replace -->` replaced with `<h1>envoy added content</h1>` in the output either via a curl or via the browser.

# ports

* envoy - [localhost:8000](http://localhost:8000)
* envoy service1 - [localhost:8000/service/1](http://localhost:8000/service/1)
* envoy service2 - [localhost:8000/service/2](http://localhost:8000/service/2)
* caddy service1 - [localhost:8011/](http://localhost:8011/)
* caddy service2 - [localhost:8002/](http://localhost:8012/)
