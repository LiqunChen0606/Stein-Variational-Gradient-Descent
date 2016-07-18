clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sample code to reproduce our results of bayesian logistic regression
% Covertype dataset is available at: https://archive.ics.uci.edu/ml/machine-learning-databases/covtype/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

M = 100; % number of particles

% we partition the data into 80% for training and 20% for testing
train_ratio = 0.8;
max_iter = 6000;

% build up training and testing dataset
load covtype.mat;
X = covtype(:,2:end); y = covtype(:,1); y(y==2) = -1;

X = [X, ones(size(X,1),1)];  % the bias parameter is absorbed by including 1 as an entry in x
[N, d] = size(X); D = d+1; % w and alpha

% building training and testing dataset
train_idx = randperm(N, round(train_ratio*N));  test_idx = setdiff(1:N, train_idx);
X_train = X(train_idx, :); y_train = y(train_idx);
X_test = X(test_idx, :); y_test = y(test_idx);

n_train = length(train_idx); n_test = length(test_idx);

% example of bayesian logistic regression
batchsize = 100; % subsampled mini-batch size
a0 = 1; b0 = .01; % hyper-parameters
dlog_p = @(theta, X, y) dlog_p_lr(theta, X, y, batchsize, a0, b0); % returns the first order derivative of the posterior distribution 

% initlization for particles using the prior distribution
alpha0 = gamrnd(a0, b0, M, 1); theta0 = zeros(M, D);
for i = 1:M
    theta0(i,:) = [normrnd(0, sqrt((1/alpha0(i))), 1, d), log(alpha0(i))]; % w and log(alpha)
end

% our variational gradient descent algorithm

% Searching best master_stepsize using a development set
% master_stepsize = cv_search_stepsize(X_train, y_train, theta0, dlog_p);
master_stepsize = 0.05;  

tic
dlog_p  = @(theta)dlog_p(theta, X_train, y_train); % fix training set
theta_vgd = vgd(theta0, dlog_p, max_iter, master_stepsize);
time = toc;

% evaluation
[acc_vgd, llh_vgd] = bayeslr_evaluation(theta_vgd, X_test, y_test);
fprintf('Result of VGD: testing accuracy: %f; testing loglikelihood: %f\n', acc_vgd, llh_vgd);
