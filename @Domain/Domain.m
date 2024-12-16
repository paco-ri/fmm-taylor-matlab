classdef Domain
    %DOMAIN A class describing a domain in which Taylor states are solved
    %   This class is a wrapper class for the surfacemesh and surfer 
    %   classes 

    properties
        nsurfaces % number of nested toroidal surfaces (1 or 2)
        dom % surface as a surfacefun.surfacemesh
        surf % surface as an fmm3dbie.surfer
        % domparams % parameters describing surface
        % nptspersurf % number of points on each surface
        vn % outward unit normal vector on surface 
        mH % surface harmonic vector field on surface 
        L % surfaceop for Laplace-Beltrami operator on surf
        aquad % A-cycle quadrature
        bquad % B-cycle quadrature
        param % parametrization of the surface
    end

    methods
        function obj = Domain(domain)
            %UNTITLED3 Construct an instance of a Domain
            %   Arguments: see above
            if isa(domain, 'surfacemesh')
                obj.nsurfaces = 1;
                obj.dom = {domain};
                surf = surfer.surfacemesh_to_surfer(domain);
                obj.surf = {surf};
                obj.vn = {normal(domain)};
            elseif length(domain) == 2
                if isa(domain{1}, 'surfacemesh') && isa(domain{2}, 'surfacemesh')
                    obj.nsurfaces = 2;
                    obj.dom = domain;
                    surf = cell(1,2);
                    surf{1} = surfer.surfacemesh_to_surfer(domain{1});
                    surf{2} = surfer.surfacemesh_to_surfer(domain{2});
                    obj.surf = surf;
                    vn = cell(1,2);
                    vn{1} = normal(domain{1});
                    vn{2} = -1.*normal(domain{2}); % flip inner normal
                    obj.vn = vn;
                end
            else
                error(['Invalid call to Domain constructor. ' ...
                    'First argument should be a surfacemesh or a cell ' ...
                    'array with two surfacemeshes.'])
            end

            obj.L = cell(1,obj.nsurfaces);
            pdo = [];
            pdo.lap = 1;
            for i = 1:obj.nsurfaces
                obj.L{i} = surfaceop(obj.dom{i}, pdo);
                obj.L{i}.rankdef = true;
                obj.L{i}.build();
            end

            obj.compute_mH();
        end

        function obj = compute_mH(obj)
            %COMPUTE_MH Compute surface harmonic vector field
            sinphi = @(x,y,z) y./sqrt(x.^2 + y.^2);
            cosphi = @(x,y,z) x./sqrt(x.^2 + y.^2);
            obj.mH = cell(1,obj.nsurfaces);
            for i = 1:obj.nsurfaces
                phihat = surfacefunv(@(x,y,z) -sinphi(x,y,z), ...
                     @(x,y,z) cosphi(x,y,z), ...
                     @(x,y,z) 0.*z, obj.dom{i});
                dummy = cross(obj.vn{i}, phihat); 
                    
                if i == 1
                    [~, ~, vH] = hodge(dummy);
                else
                    [~, ~, vH] = TaylorState.hodge_inward(dummy);
                end
                obj.mH{i} = vH + 1i.*cross(obj.vn{i},vH);
            end
        end
    end

    methods (Static)
        aquad = acycquad(dom,mode,varargin);
    end
end