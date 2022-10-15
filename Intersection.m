classdef Intersection<uint8%#codegen
    %  功能：用于2个平面旋转矩形求交部分类型定义，支持C代码生成
   enumeration
      INTERSECT_FULL (1)
      INTERSECT_PARTIAL (2)
      INTERSECT_NONE (3)
   end
end