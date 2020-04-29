package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"sort"
	"strings"
)

const (
	suggestionsFileName          = "suggestions"
	mergeSuggestedModuleFileName = "suggestion.mod"

	None    Section = ""
	Module  Section = "module"
	Go      Section = "go"
	Require Section = "require"
	Replace Section = "replace"
)

type Section string

func (s Section) String() string {
	return string(s)
}

type GoModuleDescriptor struct {
	Module  string
	Version string
	Require map[string]string
	Replace map[string]string
}

func main() {
	if len(os.Args) != 2 {
		fmt.Printf("Must provide 2 arguments: \n\t- plugin go.mod file path \n\t- Glooe go.mod file path\n")
		os.Exit(1)
	}

	pluginsGoModulesFilePath := os.Args[1]

	pluginModule, err := readModuleFile(pluginsGoModulesFilePath)
	if err != nil {
		fmt.Printf("Failed to read plugin module file: %s/n", err.Error())
		os.Exit(1)
	}

	suggestionsModule, err := readModuleFile(suggestionsFileName)
	if err != nil {
		fmt.Printf("Failed to read suggestions module file: %s/n", err.Error())
		os.Exit(1)
	}

	mergeModules(suggestionsModule, pluginModule)

	//write to new module file
	if err := createModuleFile(pluginModule); err != nil {
		fmt.Printf("Failed to create suggestions file: %s/n", err.Error())
		os.Exit(1)
	}

	fmt.Printf("Created suggestion go module file [%s], please use its content to replace your go.mod file\n", mergeSuggestedModuleFileName)
	os.Exit(0)

}

func mergeModules(suggestionsModule *GoModuleDescriptor, pluginModule *GoModuleDescriptor) {
	if len(suggestionsModule.Version) > 0 {
		pluginModule.Version = suggestionsModule.Version
	}
	if suggestionsModule.Require != nil {
		if pluginModule.Require == nil {
			pluginModule.Require = suggestionsModule.Require
		} else {
			//merge the required and replace entries
			for key, version := range suggestionsModule.Require {
				pluginModule.Require[key] = version
			}
		}
	}
	if suggestionsModule.Replace != nil {
		if pluginModule.Replace == nil {
			pluginModule.Replace = suggestionsModule.Replace
		} else {
			for key, with := range suggestionsModule.Replace {
				pluginModule.Replace[key] = with
			}
		}
	}
}

func readModuleFile(filePath string) (*GoModuleDescriptor, error) {
	if err := checkFile(filePath); err != nil {
		return nil, err
	}

	depFile, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	//noinspection GoUnhandledErrorResult
	defer depFile.Close()

	goModule := &GoModuleDescriptor{}

	scanner := bufio.NewScanner(depFile)
	section := None
	for scanner.Scan() {
		line := scanner.Text()

		depInfo := strings.Fields(line)
		depInfoLen := len(depInfo)

		//skip empty and closing lines
		if depInfoLen <= 1 || depInfo[0] == "//" {
			if depInfoLen == 1 && depInfo[0] == ")" {
				//closing section indicator
				section = None
			}
			continue
		}

		switch section {
		case Require:
			goModule.Require[depInfo[0]] = strings.TrimSpace(line)
		case Replace:
			goModule.Replace[depInfo[0]] = strings.TrimSpace(line)
		default:
			switch depInfo[0] {
			case Module.String():
				section = Module
				goModule.Module = depInfo[1]
				continue
			case Go.String():
				section = Go
				goModule.Version = depInfo[1]
				continue
			case Require.String():
				section = Require
				if goModule.Require == nil {
					goModule.Require = map[string]string{}
				}
				continue
			case Replace.String():
				section = Replace
				if goModule.Replace == nil {
					goModule.Replace = map[string]string{}
				}
				continue
			default:
				if depInfo[1] == "(" {
					return nil, fmt.Errorf("unkown section: [%s]. "+
						"Expected on of 'module | go | require | replace'", line)
				}
			}
		}
	}
	return goModule, scanner.Err()
}

func createModuleFile(module *GoModuleDescriptor) error {
	moduleFile, err := os.Create(mergeSuggestedModuleFileName)
	if err != nil {
		return err
	}
	//noinspection GoUnhandledErrorResult
	defer moduleFile.Close()

	// Print out the module
	_, _ = fmt.Fprintf(moduleFile, "module %s\n", module.Module)

	// Print out the version
	_, _ = fmt.Fprintf(moduleFile, "go %s\n", module.Version)

	// Print out the merged `require` section
	if requires := module.Require; len(requires) > 0 {
		_, _ = fmt.Fprintln(moduleFile, `require (
	// Merged 'require' section of the suggestions and your go.mod file:`)
		keys := getSortedKeys(requires)
		for _, r := range keys {
			_, _ = fmt.Fprintf(moduleFile, "\t%s\n", requires[r])
		}
		_, _ = fmt.Fprintln(moduleFile, ")")
	}

	// Print out the merged `replace` section
	if replaces := module.Replace; len(replaces) > 0 {
		_, _ = fmt.Fprintln(moduleFile, `replace (
	// Merged 'replace' section of the suggestions and your go.mod file:`)
		keys := getSortedKeys(replaces)
		for _, r := range keys {
			_, _ = fmt.Fprintf(moduleFile, "\t%s\n", replaces[r])
		}
		_, _ = fmt.Fprintln(moduleFile, ")")
	}
	return nil
}

func getSortedKeys(m map[string]string) []string {
	var keys []string
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

func checkFile(filename string) error {
	info, err := os.Stat(filename)
	if os.IsNotExist(err) {
		return errors.New(filename + " file not found")
	}
	if info.IsDir() {
		return errors.New(filename + " is a directory")
	}
	return nil
}
