---
title: apidoc start learn
date: 2018-08-31 16:02:53
categories:
- backend
tags:
- apidoc
- learn
---

参考: [http://apidocjs.com/](http://apidocjs.com/)

## Demo

`Javadoc-Style` (can be used in C#, Go, Dart, Java, JavaScript, PHP, TypeScript and all other Javadoc capable languages):

```go
/**
 * @api {get} /user/:id Request User information
 * @apiName GetUser
 * @apiGroup User
 *
 * @apiParam {Number} id Users unique ID.
 *
 * @apiSuccess {String} firstname Firstname of the User.
 * @apiSuccess {String} lastname  Lastname of the User.
 */
```


## install

```sh
npm install apidoc -g
```

## Run

```sh
apidoc -i myapp/ -o apidoc/ -t mytemplate/
```

## Configuration (apidoc.json)

ex:
```json
{
  "name": "example",
  "version": "0.1.0",
  "description": "apiDoc basic example",
  "title": "Custom apiDoc browser title",
  "url" : "https://api.github.com/v1"
}
```

## Header / Footer

```json
{
  "header": {
    "title": "My own header title",
    "filename": "header.md"
  },
  "footer": {
    "title": "My own footer title",
    "filename": "footer.md"
  }
}
```

## Basic

`apidoc.json`

```json
{
  "name": "example",
  "version": "0.1.0",
  "description": "A basic apiDoc example"
}
```

`example.js`

```go
/**
 * @api {get} /user/:id Request User information
 * @apiName GetUser
 * @apiGroup User
 *
 * @apiParam {Number} id Users unique ID.
 *
 * @apiSuccess {String} firstname Firstname of the User.
 * @apiSuccess {String} lastname  Lastname of the User.
 *
 * @apiSuccessExample Success-Response:
 *     HTTP/1.1 200 OK
 *     {
 *       "firstname": "John",
 *       "lastname": "Doe"
 *     }
 *
 * @apiError UserNotFound The id of the User was not found.
 *
 * @apiErrorExample Error-Response:
 *     HTTP/1.1 404 Not Found
 *     {
 *       "error": "UserNotFound"
 *     }
 */
 ```


### 继承

```go
/**
 * @apiDefine UserNotFoundError
 *
 * @apiError UserNotFound The id of the User was not found.
 *
 * @apiErrorExample Error-Response:
 *     HTTP/1.1 404 Not Found
 *     {
 *       "error": "UserNotFound"
 *     }
 */

/**
 * @api {get} /user/:id Request User information
 * @apiName GetUser
 * @apiGroup User
 *
 * @apiParam {Number} id Users unique ID.
 *
 * @apiSuccess {String} firstname Firstname of the User.
 * @apiSuccess {String} lastname  Lastname of the User.
 *
 * @apiSuccessExample Success-Response:
 *     HTTP/1.1 200 OK
 *     {
 *       "firstname": "John",
 *       "lastname": "Doe"
 *     }
 *
 * @apiUse UserNotFoundError
 */

/**
 * @api {put} /user/ Modify User information
 * @apiName PutUser
 * @apiGroup User
 *
 * @apiParam {Number} id          Users unique ID.
 * @apiParam {String} [firstname] Firstname of the User.
 * @apiParam {String} [lastname]  Lastname of the User.
 *
 * @apiSuccessExample Success-Response:
 *     HTTP/1.1 200 OK
 *
 * @apiUse UserNotFoundError
 */
```

### Versioning

```go
/**
 * @api {get} /user/:id Get User information
 * @apiVersion 0.1.0
 * @apiName GetUser
 * @apiGroup User
 *
 * @apiParam {Number} id Users unique ID.
 *
 * @apiSuccess {String} firstname Firstname of the User.
 * @apiSuccess {String} lastname  Lastname of the User.
 *
 * @apiSuccessExample Success-Response:
 *     HTTP/1.1 200 OK
 *     {
 *       "firstname": "John",
 *       "lastname": "Doe"
 *     }
 *
 * @apiError UserNotFound The id of the User was not found.
 *
 * @apiErrorExample Error-Response:
 *     HTTP/1.1 404 Not Found
 *     {
 *       "error": "UserNotFound"
 *     }
 */
```

```go
/**
 * @api {get} /user/:id Get User information and Date of Registration.
 * @apiVersion 0.2.0
 * @apiName GetUser
 * @apiGroup User
 *
 * @apiParam {Number} id Users unique ID.
 *
 * @apiSuccess {String} firstname  Firstname of the User.
 * @apiSuccess {String} lastname   Lastname of the User.
 * @apiSuccess {Date}   registered Date of Registration.
 *
 * @apiSuccessExample Success-Response:
 *     HTTP/1.1 200 OK
 *     {
 *       "firstname": "John",
 *       "lastname": "Doe"
 *     }
 *
 * @apiError UserNotFound The id of the User was not found.
 *
 * @apiErrorExample Error-Response:
 *     HTTP/1.1 404 Not Found
 *     {
 *       "error": "UserNotFound"
 *     }
 */
```

该版本可用于每个块，也可用于继承块。您不必更改继承块上的版本，解析器会自动检查最近的前任.

## apiDoc-Params

列几个常用的标签:

### @api

```apidoc
@api {method} path [title]
```

Required!
Without that indicator, apiDoc parser ignore the documentation block. (apidoc 工具的标识开始)

## @apiName

```apidoc
@apiName name
```


## @apiGroup

```apidoc
@apiGroup name
```

## @apiDefine

```apidoc
@apiDefine name [title]
    [description]
```

## @apiUse

```apidoc
@apiUse name
```
## @apiDeprecated

```apidoc
@apiDeprecated [text]
```

Ex:
```go
/**
 * @apiDeprecated
 */

/**
 * @apiDeprecated use now (#Group:Name).
 *
 * Example: to set a link to the GetDetails method of your group User
 * write (#User:GetDetails)
 */
```

## @apiDescription

```apidoc
@apiDescription text
```

Ex:
```go
/**
 * @apiDescription This is the Description.
 * It is multiline capable.
 *
 * Last line of Description.
 */
```

## @apiParam

```apidoc
@apiParam [(group)] [{type}] [field=defaultValue] [description]
```

```go
/**
 * @api {get} /user/:id
 * @apiParam {Number} id Users unique ID.
 */

/**
 * @api {post} /user/
 * @apiParam {String} [firstname]  Optional Firstname of the User.
 * @apiParam {String} lastname     Mandatory Lastname.
 * @apiParam {String} country="DE" Mandatory with default value "DE".
 * @apiParam {Number} [age=18]     Optional Age with default 18.
 *
 * @apiParam (Login) {String} pass Only logged in users can post this.
 *                                 In generated documentation a separate
 *                                 "Login" Block will be generated.
 */
```

Name      |   Description
-----     |  --------
(group)   |  All parameters will be grouped by this name. <br>Without a group, the default `Parameter` is set.<br>You can set a title and description with @apiDefine.
{type}    |  Parameter type, e.g. `{Boolean}`, `{Number}`, `{String}`, `{Object}`, `{String[]}` (array of strings), ...
{type{size}} | Information about the size of the variable.<br>`{string{..5}}` a string that has max 5 chars.<br>`{string{2..5}}` a string that has min. 2 chars and max 5 chars.<br>`{number{100-999}}` a number between 100 and 999.
{type=allowedValues} | Information about allowed values of the variable.<br>`{string="small"}` a string that can only contain the word "small" (a constant).<br>`{string="small","huge"}` a string that can contain the words "small" or "huge".<br>`{number=1,2,3,99}` a number with allowed values of 1, 2, 3 and 99.<br><br>Can be combined with size:<br>`{string {..5}="small","huge"}` a string that has max 5 chars and only contain the words "small" or "huge".
field   | Variablename
[field]	 | Fieldname with brackets define the Variable as optional.
=defaultValue | The parameters default value.
description   | Description of the field.


## @apiParamExample

```apidoc
@apiParamExample [{type}] [title]
                   example
```

```go
/**
 * @api {get} /user/:id
 * @apiParamExample {json} Request-Example:
 *     {
 *       "id": 4711
 *     }
 */
```

## @apiSuccess

```apidoc
@apiSuccess [(group)] [{type}] field [description]
```

## @apiSuccessExample

```apidoc
@apiSuccessExample [{type}] [title]
                   example
```

```go
/**
 * @api {get} /user/:id
 * @apiSuccessExample {json} Success-Response:
 *     HTTP/1.1 200 OK
 *     {
 *       "firstname": "John",
 *       "lastname": "Doe"
 *     }
 */
```

## @apiError 

```apidoc
@apiError [(group)] [{type}] field [description]
```

```go
/**
 * @api {get} /user/:id
 * @apiError UserNotFound The <code>id</code> of the User was not found.
 */
```

## @apiErrorExample

```apidoc
@apiErrorExample [{type}] [title]
                 example
```


```go
/**
 * @api {get} /user/:id
 * @apiErrorExample {json} Error-Response:
 *     HTTP/1.1 404 Not Found
 *     {
 *       "error": "UserNotFound"
 *     }
 */
```
