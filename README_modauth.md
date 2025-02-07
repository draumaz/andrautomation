# modauth
- A super-easy helper tool to create Magisk modules

## usage
- Create a service.sh file with the script you want to run
```
cat > service.sh << EOF
/system/bin/sh echo "Hello, world!"
EOF
```
- Either supply variables or go through the prompts
```
> name="package-name" \
  version="1" \
  versionCode="1" \
  author="author-name" \
  description="A short description of your package!" \
    sh modauth.sh
``` 
```
> sh modauth.sh
name: 
```
- A .zip file will be generated in the project root that you can directly install via Magisk!
