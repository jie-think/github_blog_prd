# python 项目结构

参考: https://www.cnblogs.com/harrychinese/p/python_project_structure.html

```
|- LICENSE  
|- README.md   
|- TODO.md   
|- docs  
|   |-- index.md  
|   |-- installation.md  
|   |-- quickstart.md  
|- sandman  
|   |-- __init__.py  
|   |-- exception.py  
|   |-- model.py  
|   |-- sandman.py  
|- tests  
|   |-- __init__.py  
|   |-- test_sandman.py  
|- setup.py  
|- tox.ini  
|- .gitignore  
|- requirements.txt  
|- requirements_dev.txt ,比requirements.txt多的是单元测试库 
```

## Top 10项目的研究发现:

1. readme.md和setup.py和requirements.txt放在根目录下
2. 一个项目至少有3个子目录, docs目录, root package 和tests package
3. 的python代码要放在一个package中, 而不是一般的src目录中.
4. tox 测试工具大家都在用.
5. 用pytest和nose单元测试工具比较多, 尤其是pytest

## 脚手架工具:

下载并安装cookiecutter命令行工具,
网站: [下载](https://github.com/audreyr/cookiecutter-pypackage)
pip install cookiecutter

[cookiecutter更详细的教材](http://pydanny.com/cookie-project-templates-made-easy.html)