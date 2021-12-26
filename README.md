# Magento 2 Media Downloader

This is a bash script to quickly download the catalog images for your Magento 2 development from LIVE or STAGING server.

## INSTALL
You can simply download the script file and give the executable permission.
```
curl -0 https://raw.githubusercontent.com/MagePsycho/magento2-media-downloader-bash-script/master/src/m2-media-downloader.sh -o m2-media-downloader.sh
chmod +x m2-media-downloader.sh
```

To make it system wide command
```
mv m2-media-downloader.sh ~/bin/m2-media-downloader

#OR
#mv m2-media-downloader.sh /usr/local/bin/m2-media-downloader
```

## USAGE

### Configure SSH Settings
It uses `rsync` command to download the media files from remote.  
In order to connect to remote via SSH, you need to configure the settings in either of the following locations:
1. `~/.m2media.conf` - Home Directory (global)
1. `./.m2media.conf` - Project Directory (local)

You can copy the `.m2media.conf.dist` file (sample provided in the repository) to the required location:
```
cp .m2media.conf.dist ~/.m2media.conf

# OR
# cp .m2media.conf.dist ./.m2media.conf
```

And edit the setting as
```
# Location to private key if using (absolute path)
SSH_PRIVATE_KEY=
SSH_USER="user"
SSH_HOST="host"
SSH_PORT=22

# Magento 2 root directory in remote (absolute path)
SSH_M2_ROOT_DIR="/var/www/magento2/"
```

### Execute Commands

**To display help**
```
m2-media-downloader --help
```
![M2 Media Downloader Help](https://github.com/MagePsycho/magento2-media-downloader-bash-script/raw/main/docs/magento2-media-downloader-bash-script-help.png)

**To download the category images**
```
m2-media-downloader --type=category --id=<categoryId>
```

**To download the product images**
```
m2-media-downloader --type=product --id=<productId>
```

**To update the script**
```
m2-media-downloader --update
```

## TODOS
- [x] Option to run command with `--dry-run`
- [ ] Option to download by multiple product/category ids
- [ ] Option to download entire media gallery

