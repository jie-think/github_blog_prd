# vscode snippet



golang snippet: https://github.com/microsoft/vscode-go/blob/master/snippets/go.json



## snippet 正则使用





**参考:**

https://my.oschina.net/imsole/blog/1794999

https://code.visualstudio.com/docs/editor/userdefinedsnippets



## go.json

```json
// go
{
  // Place your snippets for go here. Each snippet is defined under a snippet name and has a prefix, body and 
	// description. The prefix is what is used to trigger the snippet and the body will be expanded and inserted. Possible variables are:
	// $1, $2 for tab stops, $0 for the final cursor position, and ${1:label}, ${2:another} for placeholders. Placeholders with the 
	// same ids are connected.
	// Example:
	// "Print to console": {
	// 	"prefix": "log",
	// 	"body": [
	// 		"console.log('$1');",
	// 		"$2"
	// 	],
	// 	"description": "Log output to console"
  // }
  "log_info": {
        "prefix": "log_info",
        "body": "${1:log}.Infof(ctx, \"[@%s] $3\", ${2:fn})",
        "description": "log.Infof()"
    },
    "log_err": {
        "prefix": "log_err",
        "body": "${1:log}.Errorf(ctx, \"[@%s] $3${4:err}=%v\", ${2:fn}, $4)",
        "description": "log Errorf"
    },
    "log_warn": {
        "prefix": "log_warn",
        "body": "${1:log}.Warningf(ctx, \"[@%s] $3\", ${2:fn})",
        "description": "log Warningf"
    },
    "iferr_log": {
        "prefix": "iferr_log",
        "body": [
            "if ${1:err} != nil {",
            "    ${2:log}.Errorf(ctx, \"[@%s] $4$1=%v\", ${3:fn}, $1)",
            "}"
        ]
    },
}
```

