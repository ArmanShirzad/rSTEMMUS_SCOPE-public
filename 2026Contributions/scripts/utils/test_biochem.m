% test_biochem.m
% Simple script to evaluate if Octave handles the nested functions correctly 
% by comparing outputs against MATLAB

% Step 1: Set up dummy `biochem_in` matching a typical timestep
biochem_in = struct();
biochem_in.Cs = 415;         % umol/mol
biochem_in.Q = 800;          % PAR
biochem_in.fPAR = 0.9;
biochem_in.T = 25;           % degC
biochem_in.eb = 15;          % hPa
biochem_in.O = 210;          % mmol/mol
biochem_in.p = 1013;         % hPa
biochem_in.Vcmax25 = 50;
biochem_in.BallBerrySlope = 9;
biochem_in.BallBerry0 = 0.01; % Triggers iteration
biochem_in.RdPerVcmax25 = 0.015;
biochem_in.Type = 'C3';
biochem_in.tempcor = 1;
biochem_in.stressfactor = 1;
biochem_in.Fluorescence_model = 1;
biochem_in.Knparams = [2.48, 2.83, 0.114];
biochem_in.po0 = [];
biochem_in.Tparams = [0.2, 0.3, 280, 310, 318];

% Add the path to the equations/utils
addpath('rSTEMMUS_SCOPE/src');

% Run biochemical
biochem_out = biochemical(biochem_in, 1, []);

% Print to terminal
fprintf('\n--- BIOCHEMICAL OUTPUT ---\n');
fprintf('A (Net Assimilation) : %.6f umol/m2/s\n', biochem_out.A);
fprintf('Ci (Internal CO2)    : %.6f umol/mol\n', biochem_out.Ci);
fprintf('gs (Stomatal Cond)   : %.6f mol/m2/s\n', biochem_out.gs);
fprintf('rcw (Leaf Resistance): %.6f s/m\n', biochem_out.rcw);
fprintf('fcount (Iterations)  : %d\n', biochem_out.fcount);
fprintf('----------------------------\n\n');
