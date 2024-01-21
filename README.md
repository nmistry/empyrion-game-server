# Empyrion Survival Game Server

---

**Docker image for [Empyrion](https://empyriongame.com/) dedicated server**

The image base on Arch Linux image and uses Wine to launch server it self, in
addition to base functionality some useful scripts added.

- Added possibility to install
  [Reforged Eden](https://steamcommunity.com/sharedfiles/filedetails/?id=2550354956)
  scenario
- Possibility to configure dedicated.yaml using environment variables

## Usage

Creating storage for new container

```
docker volume create empyrion_vol
```

Start game server in background using lates image and expose game port

```
docker run \
     -p 30000:30000/udp
     --name empyrion-game-server
     --detach
     -v empyrion_vol:/runtime
     xpr0ger/empyrion-game-server:lates
```
> [!WARNING]
> To allow Linux client connect the server you have to disable EAC
```
docker run \
     -p 30000:30000/udp
     --name empyrion-game-server
     --detach
     -e SERVERCONFIG_EACACTIVE="false"
     -v empyrion_vol:/runtime
     xpr0ger/empyrion-game-server:lates
```

## Installing Reforged Eden

> [!CAUTION]
> Keep in mind to download Reforged Eden from Steam Workshop you have to be logged
> in, thus you will have to specify your login and will be promoted for password
> and possibility for second
> [Steam Guard Security Code](https://help.steampowered.com/en/faqs/view/06B0-26E6-2CF8-254C)
> by steamcmd.

To install Reforged Eden run:

```
docker exec -it <CONTAINER_NAME> install_reforged_eden.sh <STEAM_LOGIN>
```

Remove old container:

```
docker stop empyrion-game-server && \
    docker rm empyrion-game-server
```

Create new container:

```
docker run \
    -p 30000:30000/udp
    --name empyrion-game-server \
    -e GAMECONFIG_CUSTOMSCENARIO="Reforged Eden" \
    # You have change save directory to start new game
    # with Reforged Eden scenario
    -e GAMECONFIG_GAMENAME="<NEW_SAVE_DIRECTORY>" \
    -v empyrion_vol:/runtime \
    xpr0ger/empyrion-game-server:lates
```

## Environment variables
Container has helper to translate environment variable to dedicated.yaml config file.

For example to change server port you have to change value:
```
ServerConfig:
    Srv_Port: 30000
```
To do so using environment you have to pass `SERVERCONFIG_SRV_PORT` to your container:
```
docker run \
     ...
     -e SERVERCONFIG_SRV_PORT="<NEW_VALUE>"
     ...
```
