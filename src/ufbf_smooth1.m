%UFBF_SMOOTH1  Unscented Forward-Backward Filtering Based Smoother
%
% Syntax:
%   [M,P] = UFBF_SMOOTH1(M,P,Y,[ia,Q,aparam,h,R,hparam,,alpha,beta,kappa,mat,same_p_a,same_p_h])
%
% In:
%   M - NxK matrix of K mean estimates from Kalman filter
%   P - NxNxK matrix of K state covariances from Kalman Filter
%   Y - Measurement vector
%  ia - Inverse prediction as a matrix IA defining
%       linear function ia(xw) = IA*xw, inline function,
%       function handle or name of function in
%       form ia(xw,param)                         (optional, default eye())
%   Q - Process noise of discrete model           (optional, default zero)
%   aparam - Parameters of a                      (optional, default empty)
%   h  - Measurement model function as a matrix H defining
%        linear function h(x) = H*x, inline function,
%        function handle or name of function in
%        form h(x,param)
%   R  - Measurement noise covariance.
%   hparam - Parameters of h              (optional, default aparam)
%   alpha - Transformation parameter      (optional)
%   beta  - Transformation parameter      (optional)
%   kappa - Transformation parameter      (optional)
%   mat   - If 1 uses matrix form         (optional, default 0)
%   same_p_a - If 1 uses the same parameters 
%              on every time step for a   (optional, default 1)
%   same_p_h - If 1 uses the same parameters 
%              on every time step for h   (optional, default 1) 
%
% Out:
%   K - Smoothed state mean sequence
%   P - Smoothed state covariance sequence
%   
% Description:
%   Two filter nonlinear smoother algorithm. Calculate "smoothed"
%   sequence from given extended Kalman filter output sequence
%   by conditioning all steps to all measurements.
%
% Example:
%   [...]
%
% See also:
%   UKF_PREDICT1, UKF_UPDATE1

% Copyright (C) 2006 Simo S�rkk�
%
% $Id: ufbf_smooth1.m,v 1.4 2006/10/01 14:12:23 ssarkka Exp $
%
% This software is distributed under the GNU General Public 
% Licence (version 2 or later); please refer to the file 
% Licence.txt, included with the software, for details.
%

function [M,P] = ufbf_smooth1(M,P,Y,ia,Q,aparam,h,R,...
			      hparam,alpha,beta,kappa,mat,same_p_a,same_p_h)

  %
  % Check which arguments are there
  %
  if nargin < 3
    error('Too few arguments');
  end
  if nargin < 4
    ia = [];
  end
  if nargin < 5
    Q = [];
  end
  if nargin < 6
    aparam = [];
  end
  if nargin < 7
    h = [];
  end
  if nargin < 8
    R = [];
  end
  if nargin < 9
    hparam = [];
  end
  if nargin < 10
    alpha = [];
  end
  if nargin < 11
    beta = [];
  end
  if nargin < 12
    kappa = [];
  end
  if nargin < 13
    mat = [];
  end
  if nargin < 14
    same_p_a = 1;
  end
  if nargin < 15
    same_p_h = 1;
  end
  
  %
  % Apply defaults
  %
  if isempty(mat)
    mat = 0;
  end
  
  %
  % Run the backward filter
  %
  BM = zeros(size(M));
  BP = zeros(size(P));
  %fm = zeros(size(M,1),1);
  %fP = 1e12*eye(size(M,1));
  fm = M(:,end);
  fP = P(:,:,end);
  BM(:,end) = fm;
  BP(:,:,end) = fP;
  for k=(size(M,2)-1):-1:1
    if isempty(hparam)
      hparams = [];
    elseif same_p_h
      hparams = hparam;
    else
      hparams = hparam{k};
    end
 
    if isempty(aparam)
      aparams = [];
    elseif same_p_a
      aparams = aparam;
    else
      aparams = aparam{k};
    end
    
    [fm,fP] = ukf_update1(fm,fP,Y(:,k+1),h,R,...
			  hparams,alpha,beta,kappa,mat);
    
    %
    % Backward prediction
    % 
    [fm,fP] = ukf_predict2(fm,fP,ia,Q,aparams);

    BM(:,k) = fm;
    BP(:,:,k) = fP;
  end

  %
  % Combine estimates
  %
  for k=1:size(M,2)-1
    tmp = inv(inv(P(:,:,k)) + inv(BP(:,:,k)));
    M(:,k) = tmp * (P(:,:,k)\M(:,k) + BP(:,:,k)\BM(:,k));
    P(:,:,k) = tmp;
  end
