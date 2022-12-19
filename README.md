# reproduction of lua script + decompressor

We want to use lua scripts to edit the html of upstream responses. We noticed that brotli and gzip responses are not decoded in the filter chain, so we need to use a decompressor. We noticed that the decompressor doesn't provide the content to the lua filter from `body()`.

## workaround

There's a [pr in this repository that shows a workaround](https://github.com/ryanmr/envoy-lua-decompressor-testing/pull/2), removing the `Accept-Encoding` header as it travels upstream so that the upstream only returns the raw content. This works for our use cases.

## tech

* envoy as a reverse proxy
    * [lua](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/lua_filter) for [rewriting html](https://www.envoyproxy.io/docs/envoy/latest/configuration/http/http_filters/lua_filter.html?highlight=lua#:~:text=There%20are%20two%20ways%20of%20doing%20this%2C%20the%20first%20one%20is%20via%20the%20body()%20API.)
* [caddy](https://caddyserver.com/v2) used as a gzip file server
* docker

## how to

```
docker compose up --build
```

If the lua is working and replacement was successful, then you should see `<p>replace</p>` replaced with `<h1>envoy added content</h1>` in the output either via a curl or via the browser.

## ports

* envoy - [localhost:8000](http://localhost:8000)
* envoy service1 - [localhost:8000/service/1](http://localhost:8000/service/1)
* envoy service2 - [localhost:8000/service/2](http://localhost:8000/service/2)
* caddy service1 - [localhost:8011/](http://localhost:8011/)
* caddy service2 - [localhost:8002/](http://localhost:8012/)

## commands

```
curl -v -H "Accept-Encoding: gzip,deflate,br" http://localhost:8000/service/1
```

```
curl -v -H "Accept-Encoding: gzip,deflate,br" http://localhost:8000/service/2
```

```
curl -v -H "Accept-Encoding: gzip,deflate,br" http://localhost:8011/
```

```
curl -v -H "Accept-Encoding: gzip,deflate,br" http://localhost:8012/
```

Add `--compressed` flag if you want curl to decompress the response, if it has to.

## origin

Some of this example was copied from [the front proxy](https://www.envoyproxy.io/docs/envoy/latest/start/sandboxes/front_proxy).

## example of the compressed body

In this example, the lua script looks like it runs before the decompressors.

When we try the decompressors _after_ the lua scripts in the filter chain, the request hangs.

<details>
<summary>click to open</summary>

```
app-envoy-1     | [2022-12-14 03:18:04.199][1][debug][main] [source/server/server.cc:253] flushing stats
app-envoy-1     | [2022-12-14 03:18:04.205][1][trace][upstream] [source/extensions/clusters/strict_dns/strict_dns_cluster.cc:107] starting async DNS resolution for service1
app-envoy-1     | [2022-12-14 03:18:04.205][1][debug][dns] [source/extensions/network/dns_resolver/cares/dns_impl.cc:354] dns resolution for service1 started
app-envoy-1     | [2022-12-14 03:18:04.206][1][trace][dns] [source/extensions/network/dns_resolver/cares/dns_impl.cc:317] Setting DNS resolution timer for 5000 milliseconds
app-envoy-1     | [2022-12-14 03:18:04.206][1][trace][upstream] [source/extensions/clusters/strict_dns/strict_dns_cluster.cc:107] starting async DNS resolution for service2
app-envoy-1     | [2022-12-14 03:18:04.206][1][debug][dns] [source/extensions/network/dns_resolver/cares/dns_impl.cc:354] dns resolution for service2 started
app-envoy-1     | [2022-12-14 03:18:04.207][1][trace][dns] [source/extensions/network/dns_resolver/cares/dns_impl.cc:317] Setting DNS resolution timer for 4999 milliseconds
app-envoy-1     | [2022-12-14 03:18:04.207][1][trace][dns] [source/extensions/network/dns_resolver/cares/dns_impl.cc:317] Setting DNS resolution timer for 5000 milliseconds
app-envoy-1     | [2022-12-14 03:18:04.208][1][debug][dns] [source/extensions/network/dns_resolver/cares/dns_impl.cc:275] dns resolution for service2 completed with status 0
app-envoy-1     | [2022-12-14 03:18:04.208][1][trace][upstream] [source/extensions/clusters/strict_dns/strict_dns_cluster.cc:115] async DNS resolution complete for service2
app-envoy-1     | [2022-12-14 03:18:04.209][1][debug][upstream] [source/common/upstream/upstream_impl.cc:451] transport socket match, socket default selected for host with address 192.168.80.4:8012
app-envoy-1     | [2022-12-14 03:18:04.209][1][debug][upstream] [source/extensions/clusters/strict_dns/strict_dns_cluster.cc:180] DNS refresh rate reset for service2, refresh rate 5000 ms
app-envoy-1     | [2022-12-14 03:18:04.209][1][debug][dns] [source/extensions/network/dns_resolver/cares/dns_impl.cc:275] dns resolution for service1 completed with status 0
app-envoy-1     | [2022-12-14 03:18:04.209][1][trace][upstream] [source/extensions/clusters/strict_dns/strict_dns_cluster.cc:115] async DNS resolution complete for service1
app-envoy-1     | [2022-12-14 03:18:04.209][1][debug][upstream] [source/common/upstream/upstream_impl.cc:451] transport socket match, socket default selected for host with address 192.168.80.3:8011
app-envoy-1     | [2022-12-14 03:18:04.209][1][debug][upstream] [source/extensions/clusters/strict_dns/strict_dns_cluster.cc:180] DNS refresh rate reset for service1, refresh rate 5000 ms
app-envoy-1     | [2022-12-14 03:18:04.610][20][trace][misc] [source/common/event/scaled_range_timer_manager_impl.cc:60] enableTimer called on 0x14bb3f56bb00 for 3600000ms, min is 3600000ms
app-envoy-1     | [2022-12-14 03:18:04.610][20][trace][connection] [source/common/network/connection_impl.cc:423] [C0] raising connection event 2
app-envoy-1     | [2022-12-14 03:18:04.610][20][debug][conn_handler] [source/server/active_tcp_listener.cc:147] [C0] new connection from 192.168.80.1:63654
app-envoy-1     | [2022-12-14 03:18:04.610][20][trace][connection] [source/common/network/connection_impl.cc:568] [C0] socket event: 3
app-envoy-1     | [2022-12-14 03:18:04.610][20][trace][connection] [source/common/network/connection_impl.cc:679] [C0] write ready
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][connection] [source/common/network/connection_impl.cc:608] [C0] read ready. dispatch_buffered_data=0
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][connection] [source/common/network/raw_buffer_socket.cc:24] [C0] read returns: 121
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][connection] [source/common/network/raw_buffer_socket.cc:38] [C0] read error: Resource temporarily unavailable
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/http1/codec_impl.cc:625] [C0] parsing 121 bytes
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/http1/codec_impl.cc:567] [C0] message begin
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][http] [source/common/http/conn_manager_impl.cc:305] [C0] new stream
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][misc] [source/common/event/scaled_range_timer_manager_impl.cc:60] enableTimer called on 0x14bb3f56bd00 for 300000ms, min is 300000ms
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C0] completed header: key=Host value=localhost:8000
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C0] completed header: key=User-Agent value=curl/7.64.1
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C0] completed header: key=Accept value=*/*
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/http1/codec_impl.cc:817] [C0] onHeadersCompleteBase
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C0] completed header: key=Accept-Encoding value=gzip,deflate,br
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/http1/codec_impl.cc:1134] [C0] Server: onHeadersComplete size=4
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/http1/codec_impl.cc:921] [C0] message complete
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][http] [source/common/http/conn_manager_impl.cc:924] [C0][S746914870485252951] request headers complete (end_stream=true):
app-envoy-1     | ':authority', 'localhost:8000'
app-envoy-1     | ':path', '/service/1'
app-envoy-1     | ':method', 'GET'
app-envoy-1     | 'user-agent', 'curl/7.64.1'
app-envoy-1     | 'accept', '*/*'
app-envoy-1     | 'accept-encoding', 'gzip,deflate,br'
app-envoy-1     |
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][http] [source/common/http/conn_manager_impl.cc:907] [C0][S746914870485252951] request end stream
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][connection] [./source/common/network/connection_impl.h:92] [C0] current connecting state: false
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][filter] [source/extensions/filters/http/decompressor/decompressor_filter.cc:81] [C0][S746914870485252951] DecompressorFilter::decodeHeaders advertise Accept-Encoding with value 'deflate,br,gzip'
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/filter_manager.cc:538] [C0][S746914870485252951] decode headers called: filter=gzip decompressor status=0
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][filter] [source/extensions/filters/http/decompressor/decompressor_filter.cc:81] [C0][S746914870485252951] DecompressorFilter::decodeHeaders advertise Accept-Encoding with value 'deflate,gzip,br'
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/filter_manager.cc:538] [C0][S746914870485252951] decode headers called: filter=brotli decompressor status=0
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:149] creating N5Envoy10Extensions11HttpFilters3Lua19StreamHandleWrapperE at 0x1fbb3bb408d0
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][lua] [source/extensions/filters/common/lua/lua.cc:39] coroutine finished
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:210] marking dead N5Envoy10Extensions11HttpFilters3Lua19StreamHandleWrapperE at 0x1fbb3bb408d0
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][http] [source/common/http/filter_manager.cc:538] [C0][S746914870485252951] decode headers called: filter=envoy.filters.http.lua status=0
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][router] [source/common/router/router.cc:470] [C0][S746914870485252951] cluster 'service1' match for URL '/service/1'
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][router] [source/common/router/router.cc:678] [C0][S746914870485252951] router decoding headers:
app-envoy-1     | ':authority', 'localhost:8000'
app-envoy-1     | ':path', '/'
app-envoy-1     | ':method', 'GET'
app-envoy-1     | ':scheme', 'http'
app-envoy-1     | 'user-agent', 'curl/7.64.1'
app-envoy-1     | 'accept', '*/*'
app-envoy-1     | 'accept-encoding', 'deflate,gzip,br'
app-envoy-1     | 'x-forwarded-proto', 'http'
app-envoy-1     | 'x-request-id', '7b859eea-0770-4dce-b32d-2f75a4232934'
app-envoy-1     | 'x-envoy-expected-rq-timeout-ms', '15000'
app-envoy-1     | 'x-envoy-original-path', '/service/1'
app-envoy-1     |
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][pool] [source/common/http/conn_pool_base.cc:78] queueing stream due to no available connections (ready=0 busy=0 connecting=0)
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][pool] [source/common/conn_pool/conn_pool_base.cc:290] trying to create new connection
app-envoy-1     | [2022-12-14 03:18:04.611][20][trace][pool] [source/common/conn_pool/conn_pool_base.cc:291] ConnPoolImplBase 0x14bb3f23a800, ready_clients_.size(): 0, busy_clients_.size(): 0, connecting_clients_.size(): 0, connecting_stream_capacity_: 0, num_active_streams_: 0, pending_streams_.size(): 1 per upstream preconnect ratio: 1
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][pool] [source/common/conn_pool/conn_pool_base.cc:145] creating a new connection (connecting=0)
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][connection] [./source/common/network/connection_impl.h:92] [C1] current connecting state: true
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][client] [source/common/http/codec_client.cc:57] [C1] connecting
app-envoy-1     | [2022-12-14 03:18:04.611][20][debug][connection] [source/common/network/connection_impl.cc:939] [C1] connecting to 192.168.80.3:8011
app-envoy-1     | [2022-12-14 03:18:04.612][20][debug][connection] [source/common/network/connection_impl.cc:958] [C1] connection in progress
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][pool] [source/common/conn_pool/conn_pool_base.cc:131] not creating a new connection, shouldCreateNewConnection returned false.
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][http] [source/common/http/filter_manager.cc:538] [C0][S746914870485252951] decode headers called: filter=envoy.filters.http.upstream_codec status=4
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][http] [source/common/http/filter_manager.cc:538] [C0][S746914870485252951] decode headers called: filter=envoy.filters.http.router status=1
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][misc] [source/common/event/scaled_range_timer_manager_impl.cc:60] enableTimer called on 0x14bb3f56bd00 for 300000ms, min is 300000ms
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][http] [source/common/http/http1/codec_impl.cc:675] [C0] parsed 121 bytes
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][connection] [source/common/network/connection_impl.cc:568] [C1] socket event: 2
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][connection] [source/common/network/connection_impl.cc:679] [C1] write ready
app-envoy-1     | [2022-12-14 03:18:04.612][20][debug][connection] [source/common/network/connection_impl.cc:688] [C1] connected
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][connection] [source/common/network/connection_impl.cc:423] [C1] raising connection event 2
app-envoy-1     | [2022-12-14 03:18:04.612][20][debug][client] [source/common/http/codec_client.cc:88] [C1] connected
app-envoy-1     | [2022-12-14 03:18:04.612][20][debug][pool] [source/common/conn_pool/conn_pool_base.cc:327] [C1] attaching to next stream
app-envoy-1     | [2022-12-14 03:18:04.612][20][debug][pool] [source/common/conn_pool/conn_pool_base.cc:181] [C1] creating stream
app-envoy-1     | [2022-12-14 03:18:04.612][20][debug][router] [source/common/router/upstream_request.cc:579] [C0][S746914870485252951] pool ready
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][router] [source/common/router/upstream_codec_filter.cc:61] [C0][S746914870485252951] proxying headers
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][connection] [source/common/network/connection_impl.cc:483] [C1] writing 263 bytes, end_stream false
app-envoy-1     | [2022-12-14 03:18:04.612][20][debug][client] [source/common/http/codec_client.cc:139] [C1] encode complete
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][http] [source/common/http/filter_manager.cc:68] [C0][S746914870485252951] continuing filter chain: filter=0x14bb3f222ea0
app-envoy-1     | [2022-12-14 03:18:04.612][20][trace][connection] [source/common/network/connection_impl.cc:679] [C1] write ready
app-envoy-1     | [2022-12-14 03:18:04.613][20][trace][connection] [source/common/network/raw_buffer_socket.cc:67] [C1] write returns: 263
app-envoy-1     | [2022-12-14 03:18:04.613][20][trace][connection] [source/common/network/connection_impl.cc:568] [C1] socket event: 2
app-envoy-1     | [2022-12-14 03:18:04.613][20][trace][connection] [source/common/network/connection_impl.cc:679] [C1] write ready
app-envoy-1     | [2022-12-14 03:18:04.629][20][trace][connection] [source/common/network/connection_impl.cc:568] [C1] socket event: 3
app-envoy-1     | [2022-12-14 03:18:04.629][20][trace][connection] [source/common/network/connection_impl.cc:679] [C1] write ready
app-envoy-1     | [2022-12-14 03:18:04.629][20][trace][connection] [source/common/network/connection_impl.cc:608] [C1] read ready. dispatch_buffered_data=0
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][connection] [source/common/network/raw_buffer_socket.cc:24] [C1] read returns: 1656
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][connection] [source/common/network/raw_buffer_socket.cc:38] [C1] read error: Resource temporarily unavailable
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:625] [C1] parsing 1656 bytes
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:567] [C1] message begin
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C1] completed header: key=Cache-Control value=no-store
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C1] completed header: key=Content-Encoding value=gzip
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C1] completed header: key=Content-Type value=text/html; charset=utf-8
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C1] completed header: key=Etag value="rmv12n2kh"
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C1] completed header: key=Last-Modified value=Wed, 14 Dec 2022 02:47:11 GMT
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C1] completed header: key=Server value=Caddy
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C1] completed header: key=Vary value=Accept-Encoding
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C1] completed header: key=Date value=Wed, 14 Dec 2022 03:18:04 GMT
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:817] [C1] onHeadersCompleteBase
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:524] [C1] completed header: key=Content-Length value=1386
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:1401] [C1] status_code 200
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:1411] [C1] Client: onHeadersComplete size=9
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][router] [source/common/router/upstream_request.cc:236] [C0][S746914870485252951] upstream response headers:
app-envoy-1     | ':status', '200'
app-envoy-1     | 'cache-control', 'no-store'
app-envoy-1     | 'content-encoding', 'gzip'
app-envoy-1     | 'content-type', 'text/html; charset=utf-8'
app-envoy-1     | 'etag', '"rmv12n2kh"'
app-envoy-1     | 'last-modified', 'Wed, 14 Dec 2022 02:47:11 GMT'
app-envoy-1     | 'server', 'Caddy'
app-envoy-1     | 'vary', 'Accept-Encoding'
app-envoy-1     | 'date', 'Wed, 14 Dec 2022 03:18:04 GMT'
app-envoy-1     | 'content-length', '1386'
app-envoy-1     |
app-envoy-1     | [2022-12-14 03:18:04.630][20][debug][router] [source/common/router/router.cc:1359] [C0][S746914870485252951] upstream headers complete: end_stream=false
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][misc] [source/common/event/scaled_range_timer_manager_impl.cc:60] enableTimer called on 0x14bb3f56bd00 for 300000ms, min is 300000ms
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:149] creating N5Envoy10Extensions11HttpFilters3Lua19StreamHandleWrapperE at 0x1fbb3bb40c60
app-envoy-1     | [2022-12-14 03:18:04.630][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:915] script log: entered envoy_on_response
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:149] creating N5Envoy10Extensions11HttpFilters3Lua16HeaderMapWrapperE at 0x1fbb3bb40750
app-envoy-1     | [2022-12-14 03:18:04.630][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:915] script log: content type =
app-envoy-1     | [2022-12-14 03:18:04.630][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:915] script log: text/html; charset=utf-8
app-envoy-1     | [2022-12-14 03:18:04.630][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:915] script log: this is text/html
app-envoy-1     | [2022-12-14 03:18:04.630][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:915] script log: getting html
app-envoy-1     | [2022-12-14 03:18:04.630][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:545] yielding for full body
app-envoy-1     | [2022-12-14 03:18:04.630][20][debug][lua] [source/extensions/filters/common/lua/lua.cc:42] coroutine yielded
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:210] marking dead N5Envoy10Extensions11HttpFilters3Lua19StreamHandleWrapperE at 0x1fbb3bb40c60
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:210] marking dead N5Envoy10Extensions11HttpFilters3Lua16HeaderMapWrapperE at 0x1fbb3bb40750
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/filter_manager.cc:1066] [C0][S746914870485252951] encode headers called: filter=envoy.filters.http.lua status=1
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:921] [C1] message complete
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][misc] [source/common/event/scaled_range_timer_manager_impl.cc:60] enableTimer called on 0x14bb3f56bd00 for 300000ms, min is 300000ms
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:219] marking live N5Envoy10Extensions11HttpFilters3Lua19StreamHandleWrapperE at 0x1fbb3bb40c60
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][lua] [source/extensions/filters/http/lua/lua_filter.cc:273] buffering body
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:210] marking dead N5Envoy10Extensions11HttpFilters3Lua19StreamHandleWrapperE at 0x1fbb3bb40c60
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/filter_manager.cc:1229] [C0][S746914870485252951] encode data called: filter=envoy.filters.http.lua status=1
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][http] [source/common/http/http1/codec_impl.cc:1483] [C1] message complete
app-envoy-1     | [2022-12-14 03:18:04.630][20][debug][client] [source/common/http/codec_client.cc:126] [C1] response complete
app-envoy-1     | [2022-12-14 03:18:04.630][20][trace][main] [source/common/event/dispatcher_impl.cc:250] item added to deferred deletion list (size=1)
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][main] [source/common/event/dispatcher_impl.cc:250] item added to deferred deletion list (size=2)
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][main] [source/common/event/dispatcher_impl.cc:250] item added to deferred deletion list (size=3)
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][misc] [source/common/event/scaled_range_timer_manager_impl.cc:60] enableTimer called on 0x14bb3f56bd00 for 300000ms, min is 300000ms
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:219] marking live N5Envoy10Extensions11HttpFilters3Lua19StreamHandleWrapperE at 0x1fbb3bb40c60
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:262] resuming body due to end stream
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:149] creating N5Envoy10Extensions7Filters6Common3Lua13BufferWrapperE at 0x1fbb3bb40840
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:915] script log: html =
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:915] script log: �  n��tVM���WT�<;r $0;
app-envoy-1     | lɱ�]$�������ꏙ�a��Kμ�z�ޫ>���??���/��.޽�;�pn�'
app-envoy-1     | O��NwB�N���1e����_���'x9�xY���z~������_P���	L
                                                                                                 BA�O=�&���螳AG���_w0aq�J��/�`�^�w�����t�������W�s΀_���-����N/��U�
                                                              ��/�x����ГL�G&#$%Z^87 �2��d�ג%���y�
                                                                                                 +
                                                                                                  �)�D�8L�+��A 1�����ߊCX�Φ8P��C	�0��8��;�t�VH���`��%��cIxamD8���ʦ~W�Iػr�Hɰ$.��g���OZ�2�m�+v�9׆j�opr�)H�@�~���pK��ݺ�
              +9X)
                  _�+~/o�@o���-�%&E���^�RR��>�ɶO3|�Z�~a
                                                       �HZ�ktE(N3|IH��t�v��/����`?z�є�=�,�~%&�i��w���_(Ŏ]��}j��/)r�x㪴�|
�t�8�g7�@�*��{�{+�V7��c+-�lxaB4m�@���v���ZƁ�;��(v��ᦽ�]���tPbG���!�U� ��\��rhC���1xt�
                                                                                    Zx)~�M�U�}L3�pV/l��6꜠i1���B?�[Z��g��71-��a���Au9GA���C����xxvSS�k��r�4�
app-envoy-1     | ��c]��77�ɴ0j�bjR��G�}�Ԑ�D�%�B�T$*?�1�w-�s�
��ypxK�	��_(Y����S�y�                                                                  �9ӆ2
                     ��/��#�x�Im��5�ga�Zl_F�����
                                                ��ش�~��3|R�,wL$��_M�"Ö�s�񕂅T$�¦�@v}�y�6�a�@��5
                                                                                             ��g��y��^�Xy��6���i�1�o�ZS|�lAȹ��?�a���� #|;ϰ%���YC^�˾�Z�y�;������P��7�z�;˭�X���^�N٤����
                                                                                K�<�̲����Lc�[��������!Z���l�Q�D��&U�q�t�_}j�S��@O��� �<h�F��x�F����σ�6�J+��RJ8�$΢��hj���(�ל�Q��&��EG�To�Vtn�l��]�6�)��Lc�W,�NX��l����M�~�������U�+�ށ: ��SWJ�Ҍ;T��S�dOҭөW�U�V[J��H�C���6��(]�Gy�^ڭ��r�^��>�Θ�
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:915] script log: new html =
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:915] script log: �  n��tVM���WT�<;r $0;
app-envoy-1     | lɱ�]$�������ꏙ�a��Kμ�z�ޫ>���??���/��.޽�;�pn�'
app-envoy-1     | O��NwB�N���1e����_���'x9�xY���z~������_P���	L
                                                                                                 BA�O=�&���螳AG���_w0aq�J��/�`�^�w�����t�������W�s΀_���-����N/��U�
                                                              ��/�x����ГL�G&#$%Z^87 �2��d�ג%���y�
                                                                                                 +
                                                                                                  �)�D�8L�+��A 1�����ߊCX�Φ8P��C	�0��8��;�t�VH���`��%��cIxamD8���ʦ~W�Iػr�Hɰ$.��g���OZ�2�m�+v�9׆j�opr�)H�@�~���pK��ݺ�
              +9X)
                  _�+~/o�@o���-�%&E���^�RR��>�ɶO3|�Z�~a
                                                       �HZ�ktE(N3|IH��t�v��/����`?z�є�=�,�~%&�i��w���_(Ŏ]��}j��/)r�x㪴�|
�t�8�g7�@�*��{�{+�V7��c+-�lxaB4m�@���v���ZƁ�;��(v��ᦽ�]���tPbG���!�U� ��\��rhC���1xt�
                                                                                    Zx)~�M�U�}L3�pV/l��6꜠i1���B?�[Z��g��71-��a���Au9GA���C����xxvSS�k��r�4�
app-envoy-1     | ��c]��77�ɴ0j�bjR��G�}�Ԑ�D�%�B�T$*?�1�w-�s�
��ypxK�	��_(Y����S�y�                                                                  �9ӆ2
                     ��/��#�x�Im��5�ga�Zl_F�����
                                                ��ش�~��3|R�,wL$��_M�"Ö�s�񕂅T$�¦�@v}�y�6�a�@��5
                                                                                             ��g��y��^�Xy��6���i�1�o�ZS|�lAȹ��?�a���� #|;ϰ%���YC^�˾�Z�y�;������P��7�z�;˭�X���^�N٤����
                                                                                K�<�̲����Lc�[��������!Z���l�Q�D��&U�q�t�_}j�S��@O��� �<h�F��x�F����σ�6�J+��RJ8�$΢��hj���(�ל�Q��&��EG�To�Vtn�l��]�6�)��Lc�W,�NX��l����M�~�������U�+�ށ: ��SWJ�Ҍ;T��S�dOҭөW�U�V[J��H�C���6��(]�Gy�^ڭ��r�^��>�Θ�
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][lua] [source/extensions/filters/http/lua/lua_filter.cc:915] script log: all done
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][lua] [source/extensions/filters/common/lua/lua.cc:39] coroutine finished
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:210] marking dead N5Envoy10Extensions11HttpFilters3Lua19StreamHandleWrapperE at 0x1fbb3bb40c60
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:210] marking dead N5Envoy10Extensions7Filters6Common3Lua13BufferWrapperE at 0x1fbb3bb40840
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][http] [source/common/http/filter_manager.cc:1229] [C0][S746914870485252951] encode data called: filter=envoy.filters.http.lua status=0
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][http] [source/common/http/filter_manager.cc:68] [C0][S746914870485252951] continuing filter chain: filter=0x14bb3f222e10
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][misc] [source/common/event/scaled_range_timer_manager_impl.cc:60] enableTimer called on 0x14bb3f56bd00 for 300000ms, min is 300000ms
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][filter] [source/extensions/filters/http/decompressor/decompressor_filter.cc:121] [C0][S746914870485252951] DecompressorFilter::encodeHeaders: ':status', '200'
app-envoy-1     | 'cache-control', 'no-store'
app-envoy-1     | 'content-encoding', 'gzip'
app-envoy-1     | 'content-type', 'text/html; charset=utf-8'
app-envoy-1     | 'etag', '"rmv12n2kh"'
app-envoy-1     | 'last-modified', 'Wed, 14 Dec 2022 02:47:11 GMT'
app-envoy-1     | 'server', 'Caddy'
app-envoy-1     | 'vary', 'Accept-Encoding'
app-envoy-1     | 'date', 'Wed, 14 Dec 2022 03:18:04 GMT'
app-envoy-1     | 'content-length', '1386'
app-envoy-1     | 'x-envoy-upstream-service-time', '18'
app-envoy-1     |
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][filter] [./source/extensions/filters/http/decompressor/decompressor_filter.h:188] [C0][S746914870485252951] do not decompress response: ':status', '200'
app-envoy-1     | 'cache-control', 'no-store'
app-envoy-1     | 'content-encoding', 'gzip'
app-envoy-1     | 'content-type', 'text/html; charset=utf-8'
app-envoy-1     | 'etag', '"rmv12n2kh"'
app-envoy-1     | 'last-modified', 'Wed, 14 Dec 2022 02:47:11 GMT'
app-envoy-1     | 'server', 'Caddy'
app-envoy-1     | 'vary', 'Accept-Encoding'
app-envoy-1     | 'date', 'Wed, 14 Dec 2022 03:18:04 GMT'
app-envoy-1     | 'content-length', '1386'
app-envoy-1     | 'x-envoy-upstream-service-time', '18'
app-envoy-1     |
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][http] [source/common/http/filter_manager.cc:1066] [C0][S746914870485252951] encode headers called: filter=brotli decompressor status=0
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][filter] [source/extensions/filters/http/decompressor/decompressor_filter.cc:121] [C0][S746914870485252951] DecompressorFilter::encodeHeaders: ':status', '200'
app-envoy-1     | 'cache-control', 'no-store'
app-envoy-1     | 'content-encoding', 'gzip'
app-envoy-1     | 'content-type', 'text/html; charset=utf-8'
app-envoy-1     | 'etag', '"rmv12n2kh"'
app-envoy-1     | 'last-modified', 'Wed, 14 Dec 2022 02:47:11 GMT'
app-envoy-1     | 'server', 'Caddy'
app-envoy-1     | 'vary', 'Accept-Encoding'
app-envoy-1     | 'date', 'Wed, 14 Dec 2022 03:18:04 GMT'
app-envoy-1     | 'content-length', '1386'
app-envoy-1     | 'x-envoy-upstream-service-time', '18'
app-envoy-1     |
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][filter] [./source/extensions/filters/http/decompressor/decompressor_filter.h:184] [C0][S746914870485252951] do decompress response: ':status', '200'
app-envoy-1     | 'cache-control', 'no-store'
app-envoy-1     | 'content-type', 'text/html; charset=utf-8'
app-envoy-1     | 'etag', '"rmv12n2kh"'
app-envoy-1     | 'last-modified', 'Wed, 14 Dec 2022 02:47:11 GMT'
app-envoy-1     | 'server', 'Caddy'
app-envoy-1     | 'vary', 'Accept-Encoding'
app-envoy-1     | 'date', 'Wed, 14 Dec 2022 03:18:04 GMT'
app-envoy-1     | 'x-envoy-upstream-service-time', '18'
app-envoy-1     |
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][http] [source/common/http/filter_manager.cc:1066] [C0][S746914870485252951] encode headers called: filter=gzip decompressor status=0
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][http] [source/common/http/conn_manager_impl.cc:1534] [C0][S746914870485252951] encoding headers via codec (end_stream=false):
app-envoy-1     | ':status', '200'
app-envoy-1     | 'cache-control', 'no-store'
app-envoy-1     | 'content-type', 'text/html; charset=utf-8'
app-envoy-1     | 'etag', '"rmv12n2kh"'
app-envoy-1     | 'last-modified', 'Wed, 14 Dec 2022 02:47:11 GMT'
app-envoy-1     | 'server', 'envoy'
app-envoy-1     | 'vary', 'Accept-Encoding'
app-envoy-1     | 'date', 'Wed, 14 Dec 2022 03:18:04 GMT'
app-envoy-1     | 'x-envoy-upstream-service-time', '18'
app-envoy-1     |
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][connection] [source/common/network/connection_impl.cc:483] [C0] writing 287 bytes, end_stream false
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][misc] [source/common/event/scaled_range_timer_manager_impl.cc:60] enableTimer called on 0x14bb3f56bd00 for 300000ms, min is 300000ms
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][http] [source/common/http/filter_manager.cc:1229] [C0][S746914870485252951] encode data called: filter=brotli decompressor status=0
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][filter] [source/extensions/filters/http/decompressor/decompressor_filter.cc:161] [C0][S746914870485252951] response data decompressed from 1386 bytes to 3329 bytes
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][http] [source/common/http/filter_manager.cc:1229] [C0][S746914870485252951] encode data called: filter=gzip decompressor status=0
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][http] [source/common/http/conn_manager_impl.cc:1544] [C0][S746914870485252951] encoding data via codec (size=3329 end_stream=false)
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][connection] [source/common/network/connection_impl.cc:483] [C0] writing 3336 bytes, end_stream false
app-envoy-1     | [2022-12-14 03:18:04.631][20][trace][misc] [source/common/event/scaled_range_timer_manager_impl.cc:60] enableTimer called on 0x14bb3f56bd00 for 300000ms, min is 300000ms
app-envoy-1     | [2022-12-14 03:18:04.631][20][debug][http] [source/common/http/conn_manager_impl.cc:1551] [C0][S746914870485252951] encoding trailers via codec:
app-envoy-1     | 'x-envoy-decompressor-basic-compressed-bytes', '1386'
app-envoy-1     | 'x-envoy-decompressor-basic-uncompressed-bytes', '3329'
app-envoy-1     |
app-envoy-1     | [2022-12-14 03:18:04.632][20][trace][connection] [source/common/network/connection_impl.cc:483] [C0] writing 5 bytes, end_stream false
app-envoy-1     | [2022-12-14 03:18:04.632][20][trace][main] [source/common/event/dispatcher_impl.cc:250] item added to deferred deletion list (size=4)
app-envoy-1     | [2022-12-14 03:18:04.632][20][trace][main] [source/common/event/dispatcher_impl.cc:250] item added to deferred deletion list (size=5)
app-envoy-1     | [2022-12-14 03:18:04.632][20][trace][misc] [source/common/event/scaled_range_timer_manager_impl.cc:60] enableTimer called on 0x14bb3f56bb00 for 3600000ms, min is 3600000ms
app-envoy-1     | [2022-12-14 03:18:04.632][20][debug][pool] [source/common/http/http1/conn_pool.cc:53] [C1] response complete
app-envoy-1     | [2022-12-14 03:18:04.632][20][debug][pool] [source/common/conn_pool/conn_pool_base.cc:214] [C1] destroying stream: 0 remaining
app-envoy-1     | [2022-12-14 03:18:04.632][20][trace][http] [source/common/http/http1/codec_impl.cc:675] [C1] parsed 1656 bytes
app-envoy-1     | [2022-12-14 03:18:04.632][20][trace][main] [source/common/event/dispatcher_impl.cc:125] clearing deferred deletion list (size=5)
app-envoy-1     | [2022-12-14 03:18:04.632][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:210] marking dead N5Envoy10Extensions11HttpFilters3Lua19StreamHandleWrapperE at 0x1fbb3bb40c60
app-envoy-1     | [2022-12-14 03:18:04.632][20][trace][lua] [./source/extensions/filters/common/lua/lua.h:210] marking dead N5Envoy10Extensions11HttpFilters3Lua19StreamHandleWrapperE at 0x1fbb3bb408d0
app-envoy-1     | [2022-12-14 03:18:04.632][20][trace][connection] [source/common/network/connection_impl.cc:568] [C0] socket event: 2
app-envoy-1     | [2022-12-14 03:18:04.633][20][trace][connection] [source/common/network/connection_impl.cc:679] [C0] write ready
app-envoy-1     | [2022-12-14 03:18:04.633][20][trace][connection] [source/common/network/raw_buffer_socket.cc:67] [C0] write returns: 3628
app-envoy-1     | [2022-12-14T03:18:04.611Z] "GET /service/1 HTTP/1.1" 200 - 0 3329 20 18 "-" "curl/7.64.1" "7b859eea-0770-4dce-b32d-2f75a4232934" "localhost:8000" "192.168.80.3:8011"
app-envoy-1     | [2022-12-14 03:18:04.644][20][trace][connection] [source/common/network/connection_impl.cc:568] [C0] socket event: 3
app-envoy-1     | [2022-12-14 03:18:04.644][20][trace][connection] [source/common/network/connection_impl.cc:679] [C0] write ready
app-envoy-1     | [2022-12-14 03:18:04.644][20][trace][connection] [source/common/network/connection_impl.cc:608] [C0] read ready. dispatch_buffered_data=0
app-envoy-1     | [2022-12-14 03:18:04.644][20][trace][connection] [source/common/network/raw_buffer_socket.cc:24] [C0] read returns: 0
app-envoy-1     | [2022-12-14 03:18:04.644][20][debug][connection] [source/common/network/connection_impl.cc:656] [C0] remote close
app-envoy-1     | [2022-12-14 03:18:04.644][20][debug][connection] [source/common/network/connection_impl.cc:250] [C0] closing socket: 0
app-envoy-1     | [2022-12-14 03:18:04.645][20][trace][connection] [source/common/network/connection_impl.cc:423] [C0] raising connection event 0
app-envoy-1     | [2022-12-14 03:18:04.645][20][trace][conn_handler] [source/server/active_stream_listener_base.cc:111] [C0] connection on event 0
app-envoy-1     | [2022-12-14 03:18:04.645][20][debug][conn_handler] [source/server/active_stream_listener_base.cc:120] [C0] adding to cleanup list
app-envoy-1     | [2022-12-14 03:18:04.645][20][trace][main] [source/common/event/dispatcher_impl.cc:250] item added to deferred deletion list (size=1)
app-envoy-1     | [2022-12-14 03:18:04.645][20][trace][main] [source/common/event/dispatcher_impl.cc:250] item added to deferred deletion list (size=2)
app-envoy-1     | [2022-12-14 03:18:04.645][20][trace][main] [source/common/event/dispatcher_impl.cc:125] clearing deferred deletion list (size=2)

```

</details>
