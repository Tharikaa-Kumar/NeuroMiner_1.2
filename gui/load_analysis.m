function handles = load_analysis(handles, varargin)

% Loop through input params
nVarIn = length(varargin);

for i = 1:nVarIn

    if strcmpi(varargin{i}, 'Subjects')
        
        handles.subjects = varargin{i+1};
    
    elseif strcmpi(varargin{i}, 'Params')
        
        handles.params = varargin{i+1};
    
    elseif strcmpi(varargin{i}, 'Analysis')
        
        handles.GDdims = varargin{i+3};
        handles = load_GDdims(handles, varargin{i+1}, handles.NM.label, handles.GDdims);

    elseif strcmpi(varargin{i}, 'Visdata')
    
        vis = varargin{i+1};
        if ~isempty(vis)
            [nM, nL] = size(vis);
            for n=1:nM
                for m=1:nL
                    handles.visdata_table(n, m) = create_visdata_tables(vis{n,m}, [], [], 'create');
                end
            end
            handles.visdata = vis;
        end
        
    elseif strcmpi(varargin{i}, 'OOCVdata')
        
        handles = load_OOCV(handles, varargin{i+1});

    elseif strcmpi(varargin{i}, 'MLIdata')
    
        mli = varargin{i+1};
        handles.MLIdata = mli; 
        if ~isfield(handles, 'MLIapp') %&& ~isnumeric(handles.MLIapp)
            %handles.MLIapp.delete;
            %handles = rmfield(handles,'MLIapp');
            handles.MLIapp = 0; 
        end
        %handles.MLIapp = 0;
        
    end
    
    
end
