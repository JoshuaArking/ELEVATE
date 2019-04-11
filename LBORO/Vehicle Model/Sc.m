classdef Sc
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        distribution_in;
        res;
        t = [0];
        v_cc = [0.0];
        my_distribution;
        pascalOrd;
        model;
        soc;
        farads;
    end
    
    properties (Constant)
        vPeak = 8.0;
    end
    
    methods
        function obj = Sc(order, vStart, farads, res, model)
            %Sc Construct an instance of this class
            %   Detailed explanation goes here
            
            if nargin < 5
                model = 'single';
            end
            
            obj.distribution_in = ones(order) .* vStart;
            obj.res             = res;
            obj.my_distribution = obj.distribution_in;
            obj.pascalOrd       = order;
            
            if strcmp(model, 'single')
                obj.model = 'cap_eq_circuit_pascal5_single_shot';
            elseif strcmp(model, 'stack')
                obj.model = 'cap_eq_circuit_pascal5_single_shot_stack';
            end
            
            obj.soc = mean(obj.my_distribution) / obj.vPeak;
            obj.farads = farads;
                
        end
        
        function obj = run(obj, dt, ampsIn)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            [ v_end, amps_delivered, soc, distribution_out ] = ...
                obj.sc_model_single_shot( dt, obj.res, ampsIn, obj.distribution_in );
            
            obj.distribution_in = distribution_out;
            obj.my_distribution = Sc.appendDistribution(...
                                    obj.my_distribution, distribution_out);
            obj                 = obj.updateVcc(v_end);
            obj                 = obj.updateT(dt);
                                    % TODO duplicate timestamp
            obj.soc = [obj.soc soc];
            
        end
        
        function obj = updateVcc(obj, vcc)
            obj.v_cc = [ obj.v_cc ; vcc ];
        end
        
        function obj = updateT(obj, dt)
            obj.t = [ obj.t ; (obj.t(end):obj.res:(obj.t(end)+dt))' ];
        end
        
        function [ v_end, amps_delivered, soc, distribution_out ] ...
                = sc_model_single_shot(obj, dt, resolution, amps_in, distribution_in)
            %sc_model_single_shot Summary of this function goes here
            %   Detailed explanation goes here
            
            verbose             = false;
            verbose_dist        = false;
            verbose_load        = false;
            
            invert_order        = false;

            % Define simulation variables
            sim_time            = double(dt);
            distribution_in     = double(distribution_in);
            amps_in             = double(amps_in);
            capacitance         = double(obj.farads); % F
            if resolution <= 0.0
                resolution      = 0.1;
            end
            
            v_init1             = Sc.createInputArray(...
                                    obj.pascalOrd, distribution_in);
                
            if verbose
                fprintf('Requested %.2eAmps. dt=%d\nDistn: %s\n', num2str(amps_in), num2str(sim_time),...
                    Sc.getDistributionString(distribution_in(end,:)));
            end

            if verbose || verbose_dist
                fprintf( '\nMatLab in:\t%s\n',...
                    Sc.getDistributionString(v_init1) );
            end

            if verbose || verbose_load
                fprintf('Load: %.3f\n', amps_in);
            end

            if verbose
                fprintf('Running %s\n', obj.model);
            end

            
            % Run Simulation
            warning('off');
            simOut              = sim(obj.model,...
                'SrcWorkspace', 'current', 'ReturnWorkspaceOutputs', 'on');
            warning('on');

            if verbose
                fprintf('...simulation finished!\n');
            end

            v_end = simOut.get('v_cc');

            v_dist = simOut.get('v_cap');

            distribution_out    = Sc.createOutputArray(obj.pascalOrd, v_dist);

            if verbose || verbose_dist
            %pause(0.1)
                fprintf( 'MatLab out:\t%s\n',...
                    Sc.getDistributionString(distribution_out) );
            end
            
            amps_delivered      = simOut.get('i_cc');
            %amps_delivered = amps_delivered(end);

            soc                 = mean(distribution_out)/obj.vPeak;
        end


        function [ v_end, amps_delivered, soc, distribution_out ] ...
                = sc_model_single_shot_stack(obj,  dt, resolution, amps_in, distribution_in)
            %UNTITLED2 Summary of this function goes here
            %   Detailed explanation goes here


            %clear all;

            model = 'cap_eq_circuit_pascal5_single_shot_stack';
            %model = 'test_model';
            verbose = false;
            verbose_distribution = true;
            verbose_load = false;
            invert_order = false;

            % Define simulation variables
            sim_time = double(dt);
            distribution_in = double(distribution_in);
            amps_in = double(amps_in);

            capacitance = 1.0; % F

            v_start = mean(distribution_in(end,:));

            if verbose
                disp(['Requested ' num2str(amps_in) ' Amps. dt=' num2str(sim_time)...
                    ' Distn: ' num2str(round(distribution_in(end,:)),2)]);
            end

            if resolution <= 0.0
                resolution = 0.1;
            end


            x=size(distribution_in);
            x=x(2);

            v_init1 = ones(5,1);
            v_init2 = ones(5,1);
            v_init3 = ones(5,1);

            if x==1
                v_init1 = v_init1 .* v_start;
                v_init2 = v_init2 .* v_start;
                v_init3 = v_init3 .* v_start;
                disp('Assuming capacitors are balanced');
            elseif x==15
                if ~invert_order
                    v_init1(1) = v_init1(1) .* distribution_in(end, 5);
                    v_init1(2) = v_init1(2) .* distribution_in(end, 4);
                    v_init1(3) = v_init1(3) .* distribution_in(end, 3);
                    v_init1(4) = v_init1(4) .* distribution_in(end, 2);
                    v_init1(5) = v_init1(5) .* distribution_in(end, 1);

                    v_init2(1) = v_init2(1) .* distribution_in(end, 10);
                    v_init2(2) = v_init2(2) .* distribution_in(end, 9);
                    v_init2(3) = v_init2(3) .* distribution_in(end, 8);
                    v_init2(4) = v_init2(4) .* distribution_in(end, 7);
                    v_init2(5) = v_init2(5) .* distribution_in(end, 6);

                    v_init3(1) = v_init3(1) .* distribution_in(end, 15);
                    v_init3(2) = v_init3(2) .* distribution_in(end, 14);
                    v_init3(3) = v_init3(3) .* distribution_in(end, 13);
                    v_init3(4) = v_init3(4) .* distribution_in(end, 12);
                    v_init3(5) = v_init3(5) .* distribution_in(end, 11);
                else
                    v_init1(1) = v_init1(1) .* distribution_in(end, 1);
                    v_init1(2) = v_init1(2) .* distribution_in(end, 2);
                    v_init1(3) = v_init1(3) .* distribution_in(end, 3);
                    v_init1(4) = v_init1(4) .* distribution_in(end, 4);
                    v_init1(5) = v_init1(5) .* distribution_in(end, 5);

                    if verbose || verbose_distribution
                        disp(v_init1);
                    end

                    v_init2(1) = v_init2(1) .* distribution_in(end, 6);
                    v_init2(2) = v_init2(2) .* distribution_in(end, 7);
                    v_init2(3) = v_init2(3) .* distribution_in(end, 8);
                    v_init2(4) = v_init2(4) .* distribution_in(end, 9);
                    v_init2(5) = v_init2(5) .* distribution_in(end, 10);

                    v_init3(1) = v_init3(1) .* distribution_in(end, 11);
                    v_init3(2) = v_init3(2) .* distribution_in(end, 12);
                    v_init3(3) = v_init3(3) .* distribution_in(end, 13);
                    v_init3(4) = v_init3(4) .* distribution_in(end, 14);
                    v_init3(5) = v_init3(5) .* distribution_in(end, 15);
                end

                %disp(['Distribution: ' num2str([v_init1, v_init2, v_init3])]);
            else
                error('Unknown distribution')
            end

            if verbose || verbose_distribution
                fprintf( '\nMatLab in: %.2f %.2f %.2f %.2f %.2f', v_init1(1), v_init1(2), v_init1(3), v_init1(4), v_init1(5) );
            end

            if verbose || verbose_load
                disp(['Load: ', num2str(amps_in)]);
            end

            if verbose
                disp(['Running ' model]);
            end

            % Run Simulation
            %sim(model, model_cs, 'ReturnWorkspaceOutputs', 'on');
            warning('off');
            simOut = sim(model, 'SrcWorkspace', 'current', 'ReturnWorkspaceOutputs', 'on');
            warning('on');

            if verbose
                disp('...done!');
            end

            v_end = simOut.get('v_cc');
            %v_end = v_end(end);

            v_dist = simOut.get('v_cap');
            %v_dist = v_dist(end, :);

            distribution_out(1)  = v_dist(end, 1);
            distribution_out(2)  = mean(v_dist(end, 2:5), 2);
            distribution_out(3)  = mean(v_dist(end, 6:11), 2);
            distribution_out(4)  = mean(v_dist(end, 12:15), 2);
            distribution_out(5)  = v_dist(end, 16);

            distribution_out(6)  = v_dist(end, 16+1);
            distribution_out(7)  = mean(v_dist(end, 16+2:16+5), 2);
            distribution_out(8)  = mean(v_dist(end, 16+6:16+11), 2);
            distribution_out(9)  = mean(v_dist(end, 16+12:16+15), 2);
            distribution_out(10) = v_dist(end, 16+16);

            distribution_out(11) = v_dist(end, 32+1);
            distribution_out(12) = mean(v_dist(end, 32+2:32+5), 2);
            distribution_out(13) = mean(v_dist(end, 32+6:32+11), 2);
            distribution_out(14) = mean(v_dist(end, 32+12:32+15), 2);
            distribution_out(15) = v_dist(end, 32+16);

            if verbose || verbose_distribution
            %pause(0.1)
                fprintf( '\nMatLab out: %.2f %.2f %.2f %.2f %.2f', distribution_out(1), distribution_out(2), distribution_out(3), distribution_out(4), distribution_out(5) );
            end



            amps_delivered = simOut.get('i_cc');
            %amps_delivered = amps_delivered(end);

            soc = 0.5;
        end

    end
    
    methods (Static)
        
        function distribution = appendDistribution(distributionSrc, distributionNew)
            distribution        = [ distributionSrc ; distributionNew ];
        end
        
        function str = getDistributionString(distribution)
            str                 = '';
            
            for i=1:length(distribution)
                str             = [str, sprintf('%.2f\t', distribution(i))];
            end
        end
        
        function v_init = createInputArray(pascalOrd, distribution, invert)
            
            if nargin < 3
                invert          = false;
            end
            
            x                   = size(distribution, 2);

            v_init              = ones(x,1);

            if pascalOrd == x
                if ~invert
                    for i=1:pascalOrd
                        v_init(i)   = v_init(i) .* distribution(end, (pascalOrd+1) - i);
                    end
                else
                    for i=1:pascalOrd
                        v_init(i)   = v_init(i) .* distribution(end, i);
                    end
                end
                else
                error('Unknown distribution')
            end
        end
        
        function v_out  = createOutputArray(pascalOrd, distribution, invert)
            if nargin < 3
                invert          = false; % TODO
            end
            
            v_out(1)            = distribution(end, 1);
            v_out(2)            = mean( distribution(end, 2:5), 2 );
            v_out(3)            = mean( distribution(end, 6:11), 2 );
            v_out(4)            = mean( distribution(end, 12:15), 2 );
            v_out(5)            = distribution(end, 16);
        end
    end
end

