function [M,P,D] = adrts_smooth(M,P,f,Q,f_param,tr_method,tr_param,same_p)
% GHRTS_SMOOTH - Additive form Gauss-Hermite Rauch-Tung-Striebel smoother
%
% Syntax:
%   [M,P,D] = GHRTS_SMOOTH(M,P,f,Q,[param,p,same_p])
%
% In:
%   M - NxK matrix of K mean estimates from Gauss-Hermite Kalman filter
%   P - NxNxK matrix of K state covariances from Gauss-Hermite filter 
%   f - Dynamic model function as a matrix A defining
%       linear function f(x) = A*x, inline function,
%       function handle or name of function in
%       form a(x,param)                   (optional, default eye())
%   Q - NxN process noise covariance matrix or NxNxK matrix
%       of K state process noise covariance matrices for each step.
%   f_param - Parameters of f(.). Parameters should be a single cell array,
%           vector or a matrix containing the same parameters for each
%           step, or if different parameters are used on each step they
%           must be a cell array of the format { param_1, param_2, ...},
%           where param_x contains the parameters for step x as a cell 
%           array, a vector or a matrix.   (optional, default empty)
%   tr_method - Approximative method for estimating the joint Gaussian distribution
%               of x and y, where x ~ N(M,P) and y = g(x).
%   tr_param - Parameters of transformation 
%   same_p - If set to '1' uses the same parameters on every time step
%            (optional, default 1) 
%
% Out:
%   M - Smoothed state mean sequence
%   P - Smoothed state covariance sequence
%   D - Smoother gain sequence
%   
% Description:
%   Gauss-Hermite Rauch-Tung-Striebel smoother algorithm. Calculate
%   "smoothed" sequence from given Kalman filter output sequence by
%   conditioning all steps to all measurements.
%
% Example:
%   m = m0;
%   P = P0;
%   MM = zeros(size(m,1),size(Y,2));
%   PP = zeros(size(m,1),size(m,1),size(Y,2));
%   for k=1:size(Y,2)
%     [m,P] = adf_predict(M,P,f_func,Q,f_params{k},tr_method,tr_param_f);
%     [m,P] = adf_update(M,P,Y(:,k),h_func,R,h_params{k},tr_method,tr_param_h);
%     MM(:,k) = m;
%     PP(:,:,k) = P;
%   end
%   [SM,SP] = adrts_smooth(MM,PP,f,Q,f_params,tr_method,tr_param,0);
%
% See also:
%   ADF_PREDICT, ADF_UPDATE

% History:
%   Oct 2, 2010 - Initial version

% Copyright (C) 2010 Hartikainen, Särkkä, Solin
%
% $Id: ghrts_smooth.m,v 1.2 2009/07/01 06:34:42 ssarkka Exp $
%
% This software is distributed under the GNU General Public 
% Licence (version 2 or later); please refer to the file 
% Licence.txt, included with the software, for details.
%%

  %
  % Check which arguments are there
  %
  if nargin < 4
    error('Too few arguments');
  end
  if nargin < 5
    f_param = [];
  end
  if nargin < 7
    tr_param = [];
  end
  if nargin < 8
    same_p = 1;
  end

  %
  % Apply defaults
  %
  if isempty(f)
    f = eye(size(M,1));
  end
  if isempty(Q)
    Q = zeros(size(M,1));
  end
  
  %
  % Extend Q if NxN matrix
  %
  if size(Q,3)==1
    Q = repmat(Q,[1 1 size(M,2)]);
  end

  %
  % Run the smoother
  %
  D = zeros(size(M,1),size(M,1),size(M,2));
  if isempty(f_param)
    for k=(size(M,2)-1):-1:1
      [m_pred,P_pred,C] = feval(tr_method,M(:,k),P(:,:,k),f,[],tr_param);  
      P_pred = P_pred + Q(:,:,k);
      D(:,:,k) = C / P_pred;
      M(:,k)   = M(:,k) + D(:,:,k) * (M(:,k+1) - m_pred);
      P(:,:,k) = P(:,:,k) + D(:,:,k) * (P(:,:,k+1) - P_pred) * D(:,:,k)';
    end  
  else
    for k=(size(M,2)-1):-1:1
      if isempty(f_param)
        params = [];
      elseif same_p
        params = f_param;
      else
        params = f_param{k};
      end
      [m_pred,P_pred,C] = feval(tr_method,M(:,k),P(:,:,k),f,params,tr_param);
      P_pred = P_pred + Q(:,:,k);
      D(:,:,k) = C / P_pred;
      M(:,k)   = M(:,k) + D(:,:,k) * (M(:,k+1) - m_pred);
      P(:,:,k) = P(:,:,k) + D(:,:,k) * (P(:,:,k+1) - P_pred) * D(:,:,k)';
    end
  end