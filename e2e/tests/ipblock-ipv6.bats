#!/usr/bin/env bats

# Note:
# These test cases, stacked, will create stacked policy rules in one multi-networkpolicy and test the
# traffic policying by ncat (nc) command.

setup() {
	cd $BATS_TEST_DIRNAME
	load "common"

	server_net1=$(get_net1_ip6 "test-ipblock-ipv6" "pod-server")
	client_a_net1=$(get_net1_ip6 "test-ipblock-ipv6" "pod-client-a")
	client_b_net1=$(get_net1_ip6 "test-ipblock-ipv6" "pod-client-b")
}

@test "setup ipblock test environments" {
	kubectl create -f ipblock-ipv6.yml
	run kubectl -n test-ipblock-ipv6 wait --for=condition=ready -l app=test-ipblock-ipv6 pod --timeout=${kubewait_timeout}
	[ "$status" -eq  "0" ]

	sleep 3
}

@test "test-ipblock-ipv6 server <-> client-a" {
	run kubectl -n test-ipblock-ipv6 exec pod-client-a -- sh -c "echo x | nc -w 1 ${server_net1} 5555"
	[ "$status" -eq  "0" ]

	run kubectl -n test-ipblock-ipv6 exec pod-server -- sh -c "echo x | nc -w 1 ${client_a_net1} 5555"
	[ "$status" -eq  "1" ]
}

@test "test-ipblock-ipv6 server <-> client-b" {
	run kubectl -n test-ipblock-ipv6 exec pod-client-b -- sh -c "echo x | nc -w 1 ${server_net1} 5555"
	[ "$status" -eq  "1" ]

	run kubectl -n test-ipblock-ipv6 exec pod-server -- sh -c "echo x | nc -w 1 ${client_b_net1} 5555"
	[ "$status" -eq  "0" ]

}

@test "cleanup environments" {
	kubectl delete -f ipblock-ipv6.yml
	run kubectl -n test-ipblock-ipv6 wait --for=delete -l app=test-ipblock-ipv6 pod --timeout=${kubewait_timeout}
	[ "$status" -eq  "0" ]
}
