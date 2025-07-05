# -*- coding: utf-8 -*-
# (C) Copyright IBM Corp. 2025.
#!/usr/bin/env python -W ignore
"""
Retrieve Endpoint URL for the region pased in.
"""

def getPublicEndpointURL(region):
  endpointURL   = {
    "us-east"  : "https://us-east.iaas.cloud.ibm.com",
    "us-south" : "https://us-south.iaas.cloud.ibm.com",
    "br-sao"   : "https://br-sao.iaas.cloud.ibm.com",
    "ca-tor"   : "https://ca-tor.iaas.cloud.ibm.com",
    "ca-mon"   : "https://ca-mon.iaas.cloud.ibm.com",
    "eu-gb"    : "https://eu-gb.iaas.cloud.ibm.com",
    "eu-de"    : "https://eu-de.iaas.cloud.ibm.com",
    "eu-es"    : "https://eu-es.iaas.cloud.ibm.com",
    "jp-tok"   : "https://jp-tok.iaas.cloud.ibm.com",
    "jp-osa"   : "https://jp-osa.iaas.cloud.ibm.com",
    "au-syd"   : "https://au-syd.iaas.cloud.ibm.com"
  }
  return endpointURL.get(region,"EndpointURL Not Found!")

def getPowerPublicEndpointURL(region):
  endpointURL   = {
    "us-east"  : "https://us-east.power-iaas.cloud.ibm.com",
    "us-south" : "https://us-south.power-iaas.cloud.ibm.com",
    "mad"      : "https://mad.power-iaas.cloud.ibm.com",
    "osa"      : "https://osa.power-iaas.cloud.ibm.com",
    "tok"      : "https://tok.power-iaas.cloud.ibm.com",
    "che"    : "https://che.power-iaas.cloud.ibm.com",
    "lon"    : "https://lon.power-iaas.cloud.ibm.com",
    "eu-de"    : "https://eu-de.power-iaas.cloud.ibm.com",
    "tor"   : "https://tor.power-iaas.cloud.ibm.com",
    "mon"   : "https://mon.power-iaas.cloud.ibm.com",
    "sao"   : "https://sao.power-iaas.cloud.ibm.com",
    "syd"   : "https://syd.power-iaas.cloud.ibm.com"
  }
  return endpointURL.get(region," Power platform EndpointURL Not Found!")
