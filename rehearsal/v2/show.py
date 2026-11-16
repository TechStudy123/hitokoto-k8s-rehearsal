import json,sys
n=sys.argv[1]; full=len(sys.argv)>2
d=json.load(open(f"h{n}.json",encoding="utf-8"))
print("=== H",n,"NG:",[x["n"] for x in d if not x["ok"]])
for x in d:
    o=x.get("out","").replace("__CWD__=/workspaces/hitokoto-k8s-rehearsal\n","")
    if x["t"]=="cmd": print("$",x["msg"][:120]); print(o if full else o[-900:])
    elif not x["ok"]: print("  !!NG",x["msg"][:300])
    elif "WARN" in x["msg"]: print("  !!",x["msg"][:200])
