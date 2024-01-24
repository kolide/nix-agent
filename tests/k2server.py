#!/usr/bin/env python3
import json
from flask import Flask, jsonify, request, Response

application = Flask(__name__)
agent_flags_hash = "8c3503bd-c9f7-4503-ba8e-a51215e3e565"

# Device Server: JSONRPC endpoint
@application.route("/", methods=['POST'])
def jsonrpc():
    # Check `method` param: RequestEnrollment and RequestConfig require specific responses
    req_body = request.get_json()
    if req_body["method"] == "RequestEnrollment":
        return jsonify({
            "result": {
                "node_key": "abd",
                "node_invalid": False
            },
            "error": None,
            "id": 0
        })
    elif req_body["method"] == "RequestConfig":
        return jsonify({
            "result": {
                "config": json.dumps({
                    "options": {
                        "audit_allow_config": False,
                        "audit_allow_fim_events": False,
                        "audit_allow_process_events": False,
                        "audit_allow_fork_process_events": False,
                        "audit_allow_selinux_events": False,
                        "audit_allow_sockets": False,
                        "audit_allow_user_events": False,
                        "disable_audit": False,
                        "disable_events": False,
                        "enable_file_events": False,
                        "events_max": 10000,
                        "enable_bpf_events": False,
                        "events_expiry": 3601,
                        "read_max": 52428800,
                        "logger_event_type": False,
                        "distributed_interval": 30,
                        "schedule_epoch": "1705518221"
                    }
                }),
                "node_invalid": False
            },
            "error": None,
            "id": 0
        })
    else:
        return jsonify({
            "result": {
                "node_invalid": False
            },
            "error": None,
            "id": 0
        })

# Control server: get challenge
@application.route("/api/agent/config", methods=['GET'])
def challenge():
    return Response(response='1676065364', status=200, mimetype='application/octet-stream')

# Control server: get subsystems and hashes
@application.route("/api/agent/config", methods=['POST'])
def subsystems():
    return jsonify({
        "token": "4223b8d9-3d29-4ec9-ba18-957650cbeff0",
        "config": {
            "agent_flags": agent_flags_hash
        }
    })

# Control server: get subsystem
@application.route("/api/agent/object/<hash>", methods=['GET'])
def get_subsystem(hash):
    if hash != agent_flags_hash:
        return '', 404
    return jsonify({"desktop_enabled": "1"})

# Version endpoint
@application.route("/version", methods=['GET'])
def version():
    r = Response(response='1', status=200, mimetype='text/html')
    r.headers['Content-Type'] = 'text/html; charset=utf-8'
    return r
