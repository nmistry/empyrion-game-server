package main

import (
	"fmt"
	"os"
	"reflect"
	"strconv"
	"strings"

	"github.com/go-yaml/yaml"
	"github.com/pkg/errors"
)

type ServerConfig struct {
	SrvPort                   uint   `env:"Srv_Port" yaml:"Srv_Port"`
	SrvName                   string `env:"Srv_Name" yaml:"Srv_Name"`
	SrvPassword               string `env:"Srv_Password,omitempty" yaml:"Srv_Password,omitempty"`
	SrvMaxPlayers             uint   `env:"Srv_MaxPlayers,omitempty" yaml:"Srv_MaxPlayers,omitempty"`
	SrvReservePlayfields      uint   `env:"Srv_ReservePlayfields,omitempty" yaml:"Srv_ReservePlayfields,omitempty"`
	SrvDescription            string `env:"Srv_Description,omitempty" yaml:"Srv_Description,omitempty"`
	SrvPublic                 bool   `env:"Srv_Public" yaml:"Srv_Public"`
	SrvStopPeriod             uint   `env:"Srv_StopPeriod,omitempty" yaml:"Srv_StopPeriod,omitempty"`
	TelEnabled                bool   `env:"Tel_Enabled,omitempty" yaml:"Tel_Enabled,omitempty"`
	TelPort                   bool   `env:"Tel_Port,omitempty" yaml:"Tel_Port,omitempty"`
	TelPwd                    string `env:"Tel_Pwd,omitempty" yaml:"Tel_Pwd,omitempty"`
	EACActive                 bool   `env:"EACActive" yaml:"EACActive"`
	SaveDirectory             string `env:"SaveDirectory,omitempty" yaml:"SaveDirectory,omitempty"`
	MaxAllowedSizeClass       uint   `env:"MaxAllowedSizeClass,omitempty" yaml:"MaxAllowedSizeClass,omitempty"`
	AllowedBlueprints         string `env:"AllowedBlueprints,omitempty" yaml:"AllowedBlueprints,omitempty"`
	HeartbeatServer           uint   `env:"HeartbeatServer,omitempty" yaml:"HeartbeatServer,omitempty"`
	HeartbeatClient           uint   `env:"HeartbeatClient,omitempty" yaml:"HeartbeatClient,omitempty"`
	LogFlags                  uint   `env:"LogFlags,omitempty" yaml:"LogFlags,omitempty"`
	DisableSteamFamilySharing bool   `env:"DisableSteamFamilySharing,omitempty" yaml:"DisableSteamFamilySharing,omitempty"`
	KickPlayerWithPing        uint   `env:"KickPlayerWithPing,omitempty" yaml:"KickPlayerWithPing,omitempty"`
	TimeoutBootingPfServer    uint   `env:"TimeoutBootingPfServer,omitempty" yaml:"TimeoutBootingPfServer,omitempty"`
	PlayerLoginParallelCount  uint   `env:"PlayerLoginParallelCount,omitempty" yaml:"PlayerLoginParallelCount,omitempty"`
	PlayerLoginVipNames       string `env:"PlayerLoginVipNames,omitempty" yaml:"PlayerLoginVipNames,omitempty"`
}

type GameConfig struct {
	GameName       string `env:"GameName,omitempty" yaml:"GameName,omitempty"`
	Mode           string `env:"Mode,omitempty" yaml:"Mode,omitempty"`
	Seed           uint   `env:"Seed" yaml:"Seed"`
	CustomScenario string `env:"CustomScenario,omitempty" yaml:"CustomScenario,omitempty"`
	SharedDataURL string `env:"SharedDataURL,omitempty" yaml:"SharedDataURL,omitempty"`
}

type Config struct {
	ServerConfig ServerConfig `env:"ServerConfig" yaml:"ServerConfig"`
	GameConfig   GameConfig   `env:"GameConfig" yaml:"GameConfig"`
}

func main() {
	defer func() {
		if r := recover(); r != nil {
			fmt.Println(r)
			os.Exit(1)
		}
		os.Exit(0)
	}()

	configReadLocation, exists := os.LookupEnv("CRL")
	if !exists {
		panic("Please specify CRL")
	}
	configWriteLocation, exists := os.LookupEnv("CWL")
	if !exists {
		panic("Please specify CWL")
	}

	config := readYamlConfig(configReadLocation)
	processEnvs(&config, "")
	writeYamlConfig(configWriteLocation, config)
}

func readYamlConfig(path string) Config {
	fileContent, err := os.ReadFile(path)
	if err != nil {
		panic(errors.Wrapf(err, "failed to read config file %s", path).Error())
	}

	config := Config{}
	err = yaml.UnmarshalStrict(fileContent, &config)
	if err != nil {
		panic(errors.Wrapf(err, "failed to unmarshal config file %s", path).Error())
	}

	return config
}

func writeYamlConfig(path string, config Config) {
	fileContent, err := yaml.Marshal(config)
	if err != nil {
		panic(errors.Wrap(err, "failed to marshal config").Error())
	}

	err = os.WriteFile(path, fileContent, 0o644)
	if err != nil {
		panic(errors.Wrapf(err, "failed to write config to file %s", path).Error())
	}
}

func processEnvs(obj any, envPrefix string) {
	rValue := reflect.ValueOf(obj)
	for i := 0; i < rValue.Elem().NumField(); i++ {
		field := rValue.Elem().Field(i)
		switch field.Kind() {
		case reflect.Struct:
			envNamePrefix, exists := getEnvTagName(reflect.Indirect(rValue).Type().Field(i))
			if !exists {
				continue
			}

			if envPrefix != "" {
				envNamePrefix = fmt.Sprintf("%s_%s", envPrefix, envNamePrefix)
			}

			processEnvs(field.Addr().Interface(), envNamePrefix)
		default:
			envName, exists := getEnvTagName(reflect.Indirect(rValue).Type().Field(i))
			if envPrefix != "" {
				envName = fmt.Sprintf("%s_%s", envPrefix, envName)
			}
			envName = strings.ToUpper(envName)

			if !exists {
				continue
			}

			envValue, exists := os.LookupEnv(envName)
			if !exists {
				continue
			}

			switch field.Kind() {
			case reflect.Uint:
				intVal, err := strconv.Atoi(envValue)
				if err != nil || intVal < 0 {
					panic(fmt.Sprintf("% variable must be unsigned integer", envName))
				}

				field.SetUint(uint64(intVal))
			case reflect.String:
				field.SetString(envValue)
			case reflect.Bool:
				field.SetBool(strings.ToLower(envValue) == "true")
			default:
				panic(fmt.Sprintf("does not have handler for type %s", field.Kind()))
			}
		}
	}
}

func getEnvTagName(field reflect.StructField) (string, bool) {
	tag := field.Tag.Get("env")
	if tag == "" {
		return "", false
	}

	envName := strings.Split(tag, ",")[0]
	return envName, envName != ""
}
