#!/usr/bin/env bats

setup() {
	cd $BATS_TEST_DIRNAME
	load "common"
	server_net1=$(get_net1_ip "test-ingress-egress" "pod-server")
	client_a_net1=$(get_net1_ip "test-ingress-egress" "pod-client-a")
	client_b_net1=$(get_net1_ip "test-ingress-egress" "pod-client-b")
}

@test "setup" {
	# create test manifests
	kubectl create -f ingress-egress.yml

	# verify all pods are available
	run kubectl -n test-ingress-egress wait --for=condition=ready -l app=test-ingress-egress pod --timeout=${kubewait_timeout}
	[ "$status" -eq  "0" ]
}

@test "test-ingress-egress check client-a -> server" {
	run kubectl -n test-ingress-egress exec pod-client-a -- sh -c "echo x | nc -w 1 ${server_net1} 5555"
	[ "$status" -eq  "0" ]
}

@test "test-ingress-egress check client-b -> server" {
	run kubectl -n test-ingress-egress exec pod-client-b -- sh -c "echo x | nc -w 1 ${server_net1} 5555"
	[ "$status" -eq  "1" ]
}

@test "test-ingress-egress check server -> client-a" {
	run kubectl -n test-ingress-egress exec pod-server -- sh -c "echo x | nc -w 1 ${client_a_net1} 5555"
	[ "$status" -eq  "1" ]
}

@test "test-ingress-egress check server -> client-b" {
	run kubectl -n test-ingress-egress exec pod-server -- sh -c "echo x | nc -w 1 ${client_b_net1} 5555"
	[ "$status" -eq  "0" ]
}

@test "cleanup environments" {
	# remove test manifests
	kubectl delete -f ingress-egress.yml
	run kubectl -n test-ingress-egress wait --for=delete -l app=test-ingress-egress pod --timeout=${kubewait_timeout}
	[ "$status" -eq  "0" ]
}
