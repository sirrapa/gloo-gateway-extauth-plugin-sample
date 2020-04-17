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
)

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
	pluginModule.Version = suggestionsModule.Version
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
	for scanner.Scan() {
		line := scanner.Text()

		depInfo := strings.Fields(line)
		depInfoLen := len(depInfo)

		//skip empty and closing lines
		if depInfoLen <= 1 || depInfo[0] == "//" {
			continue
		}

		switch depInfoLen {
		case 2:
			key := depInfo[0]
			switch key {
			case "module":
				goModule.Module = depInfo[1]
			case "go":
				goModule.Version = depInfo[1]
			case "require":
				continue
			case "replace":
				continue
			default:
				if depInfo[1] == "(" {
					return nil, fmt.Errorf("unkown section: [%s]. "+
						"Expected on of 'module | go | require | replace'", line)
				}
				if goModule.Require == nil {
					goModule.Require = map[string]string{}
				}
				goModule.Require[depInfo[0]] = strings.TrimSpace(line)
			}
		case 4:
			if goModule.Replace == nil {
				goModule.Replace = map[string]string{}
			}
			goModule.Replace[depInfo[0]] = strings.TrimSpace(line)
		default:
			return nil, fmt.Errorf("malformed dependency: [%s]. "+
				"Expected format 'NAME VERSION' or 'NAME VERSION => REPLACE_NAME REPLACE_VERSION'", line)
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
