module sirrapa.com/k8s/gloo-gateway/extauth-plugin/sample

go 1.14

require (
	github.com/envoyproxy/go-control-plane v0.9.1
	github.com/solo-io/ext-auth-plugins v0.1.1
	github.com/solo-io/go-utils v0.11.5
	go.uber.org/zap v1.13.0
	k8s.io/kubernetes v1.17.2 // indirect
)

replace (
	github.com/docker/docker => github.com/moby/moby v0.7.3-0.20190826074503-38ab9da00309

	k8s.io/api v0.0.0 => k8s.io/api v0.17.2
	k8s.io/apiextensions-apiserver v0.0.0 => k8s.io/apiextensions-apiserver v0.17.2
	k8s.io/apimachinery v0.0.0 => k8s.io/apimachinery v0.17.2
	k8s.io/apiserver v0.0.0 => k8s.io/apiserver v0.17.2
	k8s.io/cli-runtime v0.0.0 => k8s.io/cli-runtime v0.17.2
	k8s.io/client-go v0.0.0 => k8s.io/client-go v0.17.2
	k8s.io/cloud-provider v0.0.0 => k8s.io/cloud-provider v0.17.2
	k8s.io/cluster-bootstrap v0.0.0 => k8s.io/cluster-bootstrap v0.17.2
	k8s.io/code-generator v0.0.0 => k8s.io/code-generator v0.17.2
	k8s.io/component-base v0.0.0 => k8s.io/component-base v0.17.2
	k8s.io/cri-api v0.0.0 => k8s.io/cri-api v0.17.2
	k8s.io/csi-translation-lib v0.0.0 => k8s.io/csi-translation-lib v0.17.2
	k8s.io/kube-aggregator v0.0.0 => k8s.io/kube-aggregator v0.17.2
	k8s.io/kube-controller-manager v0.0.0 => k8s.io/kube-controller-manager v0.17.2
	k8s.io/kube-proxy v0.0.0 => k8s.io/kube-proxy v0.17.2
	k8s.io/kube-scheduler v0.0.0 => k8s.io/kube-scheduler v0.17.2
	k8s.io/kubectl v0.0.0 => k8s.io/kubectl v0.17.2
	k8s.io/kubelet v0.0.0 => k8s.io/kubelet v0.17.2
	k8s.io/legacy-cloud-providers v0.0.0 => k8s.io/legacy-cloud-providers v0.17.2
	k8s.io/metrics v0.0.0 => k8s.io/metrics v0.17.2
	k8s.io/sample-apiserver v0.0.0 => k8s.io/sample-apiserver v0.17.2
)
