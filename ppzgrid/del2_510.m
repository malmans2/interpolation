function v = del2(f,varargin)
%DEL2 Discrete Laplacian.
%   L = DEL2(U) when U is a matrix, is an discrete approximation of
%   0.25*del^2 u = (d^2u/dx^2 + d^2/dy^2)/4.  The matrix L is the same
%   size as U with each element equal to the difference between an 
%   element of U and the average of its four neighbors.
%
%   L = DEL2(U) when U is an N-D array, returns an approximation of
%   (del^2 u)/2/n where n is ndims(u).
%
%   L = DEL2(U,H), where H is a scalar, uses H as the spacing between
%   points in each direction (H=1 by default).
%
%   L = DEL2(U,HX,HY) when U is 2-D, uses the spacing specified by HX
%   and HY. If HX is a scalar, it gives the spacing between points in
%   the x-direction. If HX is a vector, it must be of length SIZE(U,2)
%   and specifies the x-coordinates of the points.  Similarly, if HY
%   is a scalar, it gives the spacing between points in the
%   y-direction. If HY is a vector, it must be of length SIZE(U,1) and
%   specifies the y-coordinates of the points.
%
%   L = DEL2(U,HX,HY,HZ,...) when U is N-D, uses the spacing given by
%   HX, HY, HZ, etc. 
%
%   See also GRADIENT, DIFF.

%   D. Chen, 16 March 95
%   Copyright (c) 1984-97 by The MathWorks, Inc.
%   $Revision: 5.10 $  $Date: 1997/04/08 05:22:02 $

[msg,f,ndim,loc,cflag] = parse_inputs(f,varargin);
if ~isempty(msg), error(msg); end

% Loop over each dimension. Permute so that the del2 is always taken along
% the columns.

if ndim == 1
  perm = [1 2];
else
  perm = [2:ndim 1]; % Cyclic permutation
end

v = zeros(size(f));
for k = 1:ndim
   [n,p] = size(f);
   h = loc{k}(:);   
   g  = zeros(size(f)); % case of singleton dimension

   % Take forward second differences on left and right edges (based on
   % a third order approximation)
   if n > 2
      g(1,:) = (f(1,:)-2*f(2,:)+f(3,:))./(h(3)-h(1));
      g(n,:) = (f(n,:)-2*f(n-1,:)+f(n-2,:))./(h(end)-h(end-2));
   end

   % Take centered second differences on interior points
   if n > 2
      h = h(3:n) - h(1:n-2);
      g(2:n-1,:) = (f(3:n,:)-2*f(2:n-1,:)+f(1:n-2,:))./h(:,ones(p,1));
   end

   if ndim==1,
     v = v + g;
   else
     v = v + ipermute(g,[k:ndim 1:k-1]);
   end

   % Set up for next pass through the loop
   f = permute(f,perm);
end 
v = v./ndims(f);

if cflag, v = v.'; end



%-------------------------------------------------------
function [msg,f,ndim,loc,cflag] = parse_inputs(f,v)
%PARSE_INPUTS
%   [MSG,F,LOC,CFLAG] = PARSE_INPUTS(F,V) returns the spacing LOC
%   along the x,y,z,... directions and a column vector flag CFLAG. MSG
%   will be non-empty if there is an error.

msg = '';
nin = length(v)+1;
loc = {};

% Flag vector case and column vector case.
ndim = ndims(f);
vflag = 0; cflag = 0;
if ndims(f) == 2
   if size(f,2) == 1
      ndim = 1; vflag = 1; cflag = 0;
   elseif size(f,1) == 1    % Treat row vector as a column vector
      ndim = 1; vflag = 1; cflag = 1;
      f = f.';
   end;
end;
   
indx = size(f);

% Default step sizes: hx = hy = hz = 1
if nin == 1, % del2(f)
   for k = 1:ndims(f)
      loc(k) = {1:indx(k)};
   end;

elseif (nin == 2) % del2(f,h)
   % Expand scalar step size
   if (length(v{1})==1)
      for k = 1:ndims(f)
         h = v{1};
         loc(k) = {h*(1:indx(k))};
      end;
   % Check for vector case
   elseif vflag
      loc(1) = v(1);
   else
      msg = 'Invalid inputs to DEL2.';
   end

elseif ndims(f) == prod(size(v)), % del2(f,hx,hy,hz,...)
   % Swap 1 and 2 since x is the second dimension and y is the first.
   loc = v;
   if ndim>1
     tmp = loc{1};
     loc{1} = loc{2};
     loc{2} = tmp;
   end

   % replace any scalar step-size with corresponding position vector
   for k = 1:ndims(f)
      if length(loc{k})==1
         loc{k} = loc{k}*(1:indx(k));
      end;
   end;

else
   msg = 'Invalid inputs to DEL2.';

end;
