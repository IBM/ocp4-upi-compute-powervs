%{ for index, worker in worker_objects ~}
${worker.pi_network[0].mac_address},${worker.pi_network[0].ip_address},worker-${index}
%{ endfor ~}