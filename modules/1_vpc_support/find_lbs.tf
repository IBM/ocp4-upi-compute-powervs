################################################################
# Copyright 2025 - IBM Corporation. All rights reserved
# SPDX-License-Identifier: Apache-2.0
################################################################

# ibm_is_lbs - https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_lb#private_ip-6
# in the resource provider that uses this data, we must add `lifecycle { ignore_changes = all }`

data "ibm_resource_group" "group" {
  name = data.ibm_is_vpc.vpc.resource_group_name
}

# only get the subnets in the vpc
data "ibm_is_subnets" "subnets" {
  vpc = data.ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

# gets all lbs in the region
data "ibm_is_lbs" "lbs" {
    // Empty
}

locals {
    subnets_used_in_vpc = [for sn in data.ibm_is_subnets.subnets.subnets: sn.id]

    // Load Balancer Id
    subnets_from_lbs_with_ips = flatten([
        for lb in data.ibm_is_lbs.lbs.load_balancers: 
            flatten([
                for sn in lb.subnets[*]: 
                    flatten([
                        for snx in data.ibm_is_subnets.subnets.subnets:
                            sn.id == snx.id && snx.vpc == data.ibm_is_vpc.vpc.id && length(lb.private_ip) > 0 ?
                                [{
                                    id = lb.id
                                    lb_name = lb.name
                                    sn = sn
                                    vpc = data.ibm_is_vpc.vpc.id
                                    private_ip = lb.private_ip[*].address
                                }]
                                : []
                    ])
            ])
    ])

    load_balancer_ips = distinct(flatten([for slip in local.subnets_from_lbs_with_ips:
            !strcontains(slip.lb_name, "-api-")?
            flatten(
                [for pip in slip.private_ip: pip]):
            []]))
}