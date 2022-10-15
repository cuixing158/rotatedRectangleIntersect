function [intersectPoints,flag] = rotatedRectangleIntersection(RotatedRect1,RotatedRect2)%#codegen
% 功能：计算两个任意旋转矩形的交点，等同于OpenCV中的函数rotatedRectangleIntersection
% 输入：RotatedRect1
%       1*5 double,形如[xcenter, ycenter, width, height,
%       yaw]，表示一个旋转矩形,yaw单位为度,x轴逆时针方向为正
%     RotatedRect2
%      1*5 double,形如[xcenter, ycenter, width, height,
%      yaw]，表示另一个旋转矩形,yaw单位为度,x轴逆时针方向为正
%
% 输出：
%    intersectPoints
%         n*2 double，不多于8个交点的坐标，形如[x,y]，无交点为空
%    flag
%        返回标志位，{INTERSECT_FULL,INTERSECT_PARTIAL,INTERSECT_NONE}之一
% reference:
%    [1] https://github.com/opencv/opencv/blob/4.x/modules/imgproc/src/intersection.cpp
%
% Email:cuixingxing150@gmail.com
% date:2022.1.19 cuixingxing create this file
% 记录：此函数设计支持高效的C代码生成，因为polyshape内建类不支持C代码生成
%    2022.1.21 优化算法，提高执行速度，最小化实现复杂度
%
% Example:
% %% 定义两个旋转矩形
% 中心坐标分别为(300,300)、(450,350)，宽高都为[600,300],方向分别为0，30度朝向
% RotatedRect1 = [300,300,600,300,0];% [centerx,centery,width,height,yaw]
% RotatedRect2 = [450,350,600,300,30];% [centerx,centery,width,height,yaw]
% v1 = getVertices(RotatedRect1);% 获取第一个矩形的4个顶点顺序点
% v2 = getVertices(RotatedRect2);% 获取第二个矩形的4个顶点顺序点
% pgon1 = polyshape(v1); % 使用matlab内建的函数创建一个矩形对象,仅方便绘图显示
% pgon2 = polyshape(v2);
% 
% %% 显示2个旋转矩形的位置，分别用蓝色星号，绿色加号显示顶点顺序
% figure;
% plot(pgon1);hold on;grid on;axis equal;
% plot(v1(:,1),v1(:,2),'b*');
% text(v1(:,1)+3,v1(:,2),string(1:size(v1,1)))
% plot(pgon2);
% plot(v2(:,1),v2(:,2),'g+');
% text(v2(:,1)+3,v2(:,2),string(1:size(v2,1)))
% 
% %% 求旋转矩形的的交点并用红色圆圈显示交集部分的顶点顺序
% % 测试rotatedRectangleIntersection自定义函数的功能
% [intersectPoints,flag] = rotatedRectangleIntersection(RotatedRect1,RotatedRect2);
% plot(intersectPoints(:,1),intersectPoints(:,2),'ro');
% text(intersectPoints(:,1)+3,intersectPoints(:,2),...
%     string(1:size(intersectPoints,1)))
% title('平面2个旋转矩形的交集(红色圆圈围成)')
%
pts1 = getVertices(RotatedRect1);% 获取顺序的4个角点
pts2 = getVertices(RotatedRect2);
allpts = [pts1(:);pts2(:)];
samePointEps = eps(max(allpts,[],'all'));

%% 判读是否重合,INTERSECT_FULL
issame = all(abs(pts1-pts2)<samePointEps,'all');
if issame
    intersectPoints = pts1;
    flag = Intersection.INTERSECT_FULL;
    return;
end

%% 2个旋转矩形求所有交点，通过两两所在的线段直线求解，数学分析见mysolve.mlx
vertices = zeros(0,2);
coder.varsize('vertices');
for i = 1:4
    x1 = pts1(i,1);y1 = pts1(i,2);
    if i==4
        x2 = pts1(1,1);y2 = pts1(1,2);
    else
        x2 = pts1(i+1,1);y2 = pts1(i+1,2);
    end
    for j = 1:4
        m1 = pts2(j,1);n1 = pts2(j,2);
        if j==4
            m2 = pts2(1,1);n2 = pts2(1,2);
        else
            m2 = pts2(j+1,1);n2 = pts2(j+1,2);
        end
        x = (m1*n2*x1 - m2*n1*x1 - m1*n2*x2 + m2*n1*x2 - m1*x1*y2 + ...
            m1*x2*y1 + m2*x1*y2 - m2*x2*y1)/(m1*y1 - n1*x1 - m1*y2 -...
            m2*y1 + n1*x2 + n2*x1 + m2*y2 - n2*x2);
        y = (m1*n2*y1 - m2*n1*y1 - m1*n2*y2 + m2*n1*y2 - n1*x1*y2 +...
            n1*x2*y1 + n2*x1*y2 - n2*x2*y1)/(m1*y1 - n1*x1 - m1*y2 -...
            m2*y1 + n1*x2 + n2*x1 + m2*y2 - n2*x2);
        if isinf(x)||isinf(y)||isnan(x)||isnan(y) % 为平行线无解或者重合线
            continue;
        end
        if (x-x1)*(x-x2)<=samePointEps&& (y-y1)*(y-y2)<=samePointEps&&... % 点(x,y)位于(x1,y1)、(x2,y2)之间
                (x-m1)*(x-m2)<=samePointEps&& (y-n1)*(y-n2)<=samePointEps % 点(x,y)位于(m1,n1)、(m2,n2)之间
            vertices = [vertices;x,y];
        end
    end
end

%% 根据已经求得的交点，再求这2个旋转矩形互相包围的顶点，注意边界情况已经在上述求取完毕
% 判断点是否在多边形内，最有效的办法是使用二维向量叉乘符号判断！包围的矩形使用
% 顺序的点集即可
% 第一个矩形顶点判断是否在第二个内
for i = 1:4
    candiateVertex = pts1(i,:);
    vecVertexs = pts2-repmat(candiateVertex,4,1);
    for j = 1:4
        a = vecVertexs(j,:);
        if j==4
            b = vecVertexs(1,:);
        else
            b = vecVertexs(j+1,:);
        end
        % 方向标志，一次判断周期内，若当前符号不发生正负变化，则候选顶点符合要求
        signflag = sign(a(1)*b(2)-b(1)*a(2));
        currentflag = signflag;
        if j ==1
            previousflag = signflag;
        end
        if currentflag*previousflag<=0 % 等于0为边界点，-1为外点
            break;% 跳出当前内层for循环
        end
        if j==4
            vertices = [vertices;candiateVertex];
        end
        previousflag = currentflag;
    end
end
% 同理，第二个矩形顶点判断是否在第一个内
for i = 1:4
    candiateVertex = pts2(i,:);
    vecVertexs = pts1-repmat(candiateVertex,4,1);
    for j = 1:4
        a = vecVertexs(j,:);
        if j==4
            b = vecVertexs(1,:);
        else
            b = vecVertexs(j+1,:);
        end
        % 方向标志，一次判断周期内，若当前符号不发生正负变化，则候选顶点符合要求
        signflag = sign(a(1)*b(2)-b(1)*a(2));
        currentflag = signflag;
        if j ==1
            previousflag = signflag;
        end
        if currentflag*previousflag<=0 % 等于0为边界点，-1为外点
            break;% 跳出当前内层for循环
        end
        if j==4
            vertices = [vertices;candiateVertex];
        end
        previousflag = currentflag;
    end
end

%% 没有交集就返回，无须继续执行
if isempty(vertices)
    intersectPoints = [];
    flag = Intersection.INTERSECT_NONE;
    return 
else
    flag = Intersection.INTERSECT_PARTIAL;
end

%% 去除重复点
N = size(vertices,1);
duplicatedIndex = zeros(1,0);
coder.varsize('duplicatedIndex');
for i = 1:N
    pt1 = vertices(i,:);
    for j = i+1:N % 若N改为sie(vertices,1),循环不会动态变化，不同于C++
        pt2 = vertices(j,:);
        currentDist = sqrt(sum((pt1-pt2).^2,'all'));
        if currentDist<=samePointEps
            duplicatedIndex = [duplicatedIndex,j];
        end
    end
end
if ~isempty(duplicatedIndex)
    vertices(duplicatedIndex,:) = [];
end

%% 如果有多于8个点，逐一去除最近的点
verticescopy = vertices;
while size(verticescopy,1)>8
    mindist = sqrt(sum((verticescopy(1,:)-verticescopy(2,:)).^2,'all'));
    minindex = 2;
    for i = 1:size(verticescopy,1)-1
        pt1 = verticescopy(i,:);
        for j = i+1:size(verticescopy,1)
            pt2 = verticescopy(j,:);
            currentdist = sqrt(sum((pt1-pt2).^2,'all'));
            if currentdist<mindist
                mindist = currentdist;
                minindex = j;
            end
        end
    end
    verticescopy(minindex,:)= [];% 代码生成不支持通过索引方式改变数组大小，故此句要修改
end
vertices = verticescopy;

%% 凸包顶点排序,思想：利用向量叉积确定凸包方向
N = size(vertices,1);
for i = 1:N-2
    pt1 = vertices(i,:);% 表示第i个点已经完成排序，本次循环待查找第i+1个点的坐标
    vecall = vertices(i+1:end,:)-repmat(pt1,N-i,1);% 剩余未排序的N-i个点与pt1的方向向量
    vec1 = vecall(1,:);% 待寻找的基础向量，对应的点坐标索引为第i+1个
    for j = 2:size(vecall,1)
        vec2 = vecall(j,:);% 注意！对应的点坐标在vertices数组中索引为i+j
        if vec1(1)*vec2(2)-vec2(1)*vec1(2)<0
            vec1 = vec2;
            temp = vertices(i+1,:);
            vertices(i+1,:) =  vertices(i+j,:);
            vertices(i+j,:) = temp;
            vecall = vertices(i+1:end,:)-repmat(pt1,N-i,1);
        end
    end
end
intersectPoints = vertices;
end

