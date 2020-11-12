#!/usr/bin/env python
#this is a simple Organization, Workspaces and run counter for Terraform Enterprise
import json
import requests
import os
import platform



TFE_ADDR =  os.environ.get('TFE_ADDR', 'https://app.terraform.io')
TFE_TOKEN =  os.environ.get('TFE_TOKEN', 'https://app.terraform.io')
AWS_ACCESS_KEY_ID =  os.environ.get('AWS_ACCESS_KEY_ID', '')
AWS_SECRET_ACCESS_KEY =  os.environ.get('AWS_SECRET_ACCESS_KEY', '')
AWS_SESSION_TOKEN =  os.environ.get('AWS_SESSION_TOKEN', '')

if platform.system() == 'Windows':
    with open(r'%APPDATA%\\terraform.rc') as json_file:
        data = json.load(json_file)
        print(data)
