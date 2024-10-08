*已完成基本的C99标准词法分析器，并已实现部分变异策略*

```
# 执行以下构建命令时，请先取消lexer.l中main函数的注释
make		# 生成lexer可执行程序
make run	# 简单测试运行，详见makefile
make test	# python lexer_test.py，目前脚本尚不完善
```

## TODO
+ 补充完善各类型变异，如字符串、常量变异（补充一个生成随机常量的函数）
+ 如有必要，补充词法分析器的错误处理手段（目前推测不需要）
+ 用语料库`testsuite`对lexer进行测试，验证lexer正确性，目前已初步完成`lexer_test.py`脚本
+ 移植lexer至AFL，避免新开lexer进程拖慢速度

## DONE
+ 已用AFL对lexer进行一小时模糊测试，未发现错误，故假设lexer不会因为某些特殊输入而崩溃
