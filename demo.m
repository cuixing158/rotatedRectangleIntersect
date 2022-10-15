%% 定义两个旋转矩形
% 中心坐标分别为(300,300)、(450,350)，宽高都为[600,300],方向分别为0，30度朝向
RotatedRect1 = [300,300,600,300,0];% [centerx,centery,width,height,yaw]
RotatedRect2 = [450,350,600,300,30];% [centerx,centery,width,height,yaw]
v1 = getVertices(RotatedRect1);% 获取第一个矩形的4个顶点顺序点
v2 = getVertices(RotatedRect2);% 获取第二个矩形的4个顶点顺序点
pgon1 = polyshape(v1); % 使用matlab内建的函数创建一个矩形对象,仅方便绘图显示
pgon2 = polyshape(v2);

%% 显示2个旋转矩形的位置，分别用蓝色星号，绿色加号显示顶点顺序
figure;
plot(pgon1);
hold on;grid on;
plot(pgon2);
axis equal;

%% 求旋转矩形的的交点并用红色圆圈显示交集部分的顶点顺序
% 测试rotatedRectangleIntersection自定义函数的功能
[intersectPoints,flag] = rotatedRectangleIntersection(RotatedRect1,RotatedRect2);
plot(intersectPoints(:,1),intersectPoints(:,2),'ro');
text(intersectPoints(:,1)+3,intersectPoints(:,2),...
    string(1:size(intersectPoints,1)))
title('rotated rectangle interection')

