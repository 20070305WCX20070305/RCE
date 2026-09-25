# RCE

一维对流辐射模型的简单代码实现

所有的计算默认的是行向量！！！

### `grid` 

`grid.PressureGrid`:按照一定间隔生成气压，后面这个就不变了

`grid.hight`:按照传入的气压以及温度，计算每一层的高度

### `thermo`

做诊断，对于给定的`T`和`p`判断是否要考虑对流修正。

`thermo.PotentialTem`:计算位温
