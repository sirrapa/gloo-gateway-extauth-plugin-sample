package main

import (
	"context"
	"plugin"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/solo-io/ext-auth-plugins/api"
	impl "sirrapa.com/k8s/gloo-gateway/extauth-plugin/sample/pkg"
)

var _ = Describe("Plugin", func() {

	It("can be loaded", func() {

		goPlugin, err := plugin.Open("Sample.so")
		Expect(err).NotTo(HaveOccurred())

		pluginStructPtr, err := goPlugin.Lookup("Plugin")
		Expect(err).NotTo(HaveOccurred())

		extAuthPlugin, ok := pluginStructPtr.(api.ExtAuthPlugin)
		Expect(ok).To(BeTrue())

		instance, err := extAuthPlugin.NewConfigInstance(context.TODO())
		Expect(err).NotTo(HaveOccurred())

		typedInstance, ok := instance.(*impl.Config)
		Expect(ok).To(BeTrue())

		Expect(typedInstance.RequiredHeader).To(BeEmpty())
		Expect(typedInstance.AllowedValues).To(BeEmpty())
	})
})
