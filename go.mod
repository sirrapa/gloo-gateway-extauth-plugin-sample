module sirrapa.com/k8s/gloo-gateway/extauth-plugin/sample

go 1.14

require (
	github.com/envoyproxy/go-control-plane v0.9.1
	github.com/solo-io/ext-auth-plugins v0.1.1
	github.com/solo-io/go-utils v0.11.5
	go.uber.org/zap v1.13.0
)

replace (
	github.com/docker/docker => github.com/moby/moby v0.7.3-0.20190826074503-38ab9da00309
	k8s.io/api => k8s.io/api v0.0.0-20190620084959-7cf5895f2711
)
