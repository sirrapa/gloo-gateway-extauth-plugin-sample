<h1 align="center">
    <img src="https://github.com/solo-io/ext-auth-plugin-examples/raw/master/img/gloo-plugin.png" alt="Gloo Plugins" width="440" height="309">
  <br>
  Sample External auth plugin
</h1>

This repository contains a sample implementation of the 
[ExtAuthPlugin interface](https://github.com/solo-io/ext-auth-plugins/blob/master/api/interface.go) .

When you are writing your own Ext Auth plugins, you must target a specific Gloo Enterprise version. This is because of the 
nature of Go plugins (you can find more info in [this section](https://docs.solo.io/gloo/latest/guides/dev/writing_auth_plugins/#build-helper-tools) 
of the [Auth Plugin Developer Guide](https://docs.solo.io/gloo/latest/guides/dev/writing_auth_plugins/)). 
With each release Gloo Enterprise publishes the information that you will require to replicate its build environment. 
The [External auth plugin examples](https://github.com/solo-io/ext-auth-plugin-examples) repo contains example code to create such an image.
But it also contains validation code we ideally do not want in the plugin implementation repo's.
This template repo only contains the plugin implementation code and will use the example repo's code as a dependency to build the plugin
according the validation rules defined in this dependency.

## Build 

### Makefile target plugin-image 
The `plugin-image` target runs inside a docker container using the [](Dockerfile) and download the targeted tagged version of the example repo, 
resolve, merge and compares the dependencies of your plugin module with the dependencies of the Gloo Enterprise one. 
If no exact match occurred, information about mismatches is written to stdout, which contains entries that you can add to your `go.mod` 
file to bring your dependencies in sync with the Gloo Enterprise ones (see [Possible mismatch types](#possible-mismatch-types)).
If the shared dependencies match _exactly_ (this is another constraint imposed by Go plugins, more info 
[here](https://docs.solo.io/gloo/latest/guides/dev/writing_auth_plugins/#build-helper-tools)), the plugin will be compiled and verified
for the targeted Gloo Enterprise version.

You can create the image by running the following command, where `PLUGIN_BUILDER_VERSION` is the desired External auth plugin examples version, e.g. `v0.2.1` and
`GLOOE_VERSION` is the desired Gloo Enterprise version, e.g. `1.3.4` to run a test plugin build.

```bash
PLUGIN_BUILDER_VERSION=<examples-version> \
GLOOE_VERSION=<target-glooe-version> 
make plugin-image
```

#### Configurable options
The following options can be used to create plugin images
These options can be set by changing its value in the `Makefile`, exporting them as a environment variable (`export GLOOE_VERSION=1.3.4`)
or as command argument (`GLOOE_VERSION=1.3.4 make <target>` )

| Option | Default | Description |
| ------ | ------- | ----------- |
| GO_BUILD_IMAGE | golang:1.14.0-alpine | Set this variable to the image name and version used for building the plugin.|
| GLOOE_VERSION | 1.3.1 | Set this variable to the version of GlooE you want to target |
| PLUGIN_BUILDER_MODULE_PATH | github.com/solo-io/ext-auth-plugin-examples | Set this variable to the module name of the (forked) plugin builder you want to target |
| PLUGIN_BUILDER_URL | https://github.com/solo-io/ext-auth-plugin-examples | Set this variable to the url of the (forked) plugin builder you want to target |
| PLUGIN_BUILDER_VERSION | master | Set this variable to the version of the (forked) plugin builder you want to target |
| PLUGIN_BUILD_NAME | Sample.so | Set this variable to the name of your build plugin |
| PLUGIN_VERSION | 0.0.1 | Set this variable to the version of your plugin |
| RUN_IMAGE | alpine:3.11 | Set this variable to the image name and version used for running the plugin |
| STORAGE_HOSTNAME | storage.googleapis.com | Set this variable to the hostname of your custom (air gapped) storage server |


#### Possible mismatch types
There are four different types of dependency incompatibilities that can be detected.

##### `Require`
- Display message: __"Please pin your dependency to the same version as the Gloo one using a [require] clause"__
- Cause: this error occurs when both your plugin and Gloo require different versions of the same module via a `require` 
statement.
- Solution: update your `go.mod` file so that the `require` entry for the module matches the version that Gloo requires.

##### `PluginMissingReplace`
- Display message: __"Please add a [replace] clause matching the Gloo one"__
- Cause: this error occurs when your plugin requires a module via a `require` statement, but Gloo defines a `replace` 
for the same module. This is a problem, as your plugin will most likely end up with a different version of that shared 
module dependency.
- Solution: add a `replace` entry that matches the one in Gloo to your `go.mod` file.

##### `ReplaceMismatch`
- Display message: __"The plugin [replace] clause must match the Gloo one"__
- Cause: this error occurs when both your plugin and Gloo define different replacements for the same module via `replace` 
statements.
- Solution: update your `go.mod` file so that the `replace` entry for the module matches the Gloo one.

##### `PluginExtraReplace`
- Display message: __"Please remove the [replace] clause and pin your dependency to the same version as the Gloo one 
using a [require] clause"__
- Cause: this error occurs when your plugin defines a replacement for a module via a `replace` statement, but Gloo defines 
a `require` (but no `replace`) for the same module. This is a problem for the same reasons mentioned in `PluginMissingReplace`.
- Solution: since there is no way for you to modify the Gloo `go.mod` file, the only solution to this error is to remove 
the offending `replace` entry from your `go.mod` file and add a `require` entry matching the Gloo one. If this is not 
possible given the dependencies of your plugin, please join [solo-io community Slack](https://slack.solo.io/) and let them know, 
so they can think about a solution together.



