package main

import (
	"github.com/solo-io/ext-auth-plugins/api"
	impl "sirrapa.com/k8s/gloo-gateway/extauth-plugin/sample/pkg"
)

func main() {}

// Compile-time assertion
var _ api.ExtAuthPlugin = new(impl.SamplePlugin)

// This is the exported symbol that Gloo will look for.
//noinspection GoUnusedGlobalVariable
var Plugin impl.SamplePlugin
