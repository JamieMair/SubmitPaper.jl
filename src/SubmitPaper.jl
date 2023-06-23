module SubmitPaper
using Logging
using UUIDs
function find_lines(matching_start, text::AbstractArray{String})::Vector{Tuple{Int, String}}
    matching_entities = Tuple{Int, String}[]
    for (i, line) in enumerate(text)
        if startswith(strip(line), matching_start)
            push!(matching_entities, (i, line))
        end
    end

    return matching_entities
end

function find_root_files(search_dir=pwd())
    all_tex_files = [file for file in readdir(search_dir) if endswith(file, ".tex")]
    if length(all_tex_files) == 0
        error("""
        Could not find any `tex` files in the supplied directory.
        Looked in $search_dir.

        Please supply the directory containing your main tex file.
        """)
    end

    root_tex_files = String[]
    for file in all_tex_files
        file_contents = readlines(joinpath(search_dir, file))
        document_class_lines = find_lines(raw"\documentclass", file_contents)
        if length(document_class_lines) == 0
            continue
        elseif length(document_class_lines) > 1
            @info """
            `tex` file $file contains too many lines starting with `\\documentclass`.
            """
        end

        begin_document_lines = find_lines(raw"\begin{document}", file_contents)
        if length(begin_document_lines) != 1
            @info """
            $file has a `\\documentclass` but no document body (i.e. no `\\begin{document}`). Skipping...
            """
            continue
        end
            
        push!(root_tex_files, file)
    end
    return root_tex_files
end

function package_root(root_file, paper_directory=pwd(), destination_folder=joinpath(paper_directory, "submission"), force_overwrite=false)
    if !isdir(destination_folder)
        @info "Creating submission folder at $destination_folder"
        mkdir(destination_folder)
    else
        contents = readdir(destination_folder)
        if length(contents) > 0
            should_overwrite = if force_overwrite
                true
            else
                @info "Submissions folder ($destination_folder) contains files already, do you want to overwrite? (y/n):"
                user_input = readline()
                strip(user_input) == "y"
            end
            if should_overwrite
                @info "Clearing folder at $destination_folder"
                for f in contents
                    rm(joinpath(destination_folder, f), force=true, recursive=true)
                end
                if !isdir(destination_folder) # may be redundant
                    mkdir(destination_folder)
                end
            end            
        end
    end

    new_text, figure_replacements = parse_file(root_file, paper_directory)
    existing_figures = Set{String}()
    for (unique_text, figure_path) in figure_replacements
        figure_path = joinpath(paper_directory,figure_path)
        if !isfile(figure_path)
            @error "Could not find $figure_path"
        end

        filename = splitpath(figure_path)[end]
        counter = 1
        while filename in existing_figures
            filebase, ext = splitext(filename)
            filename = "$(filebase)_$(counter)$(ext)"
            counter += 1
        end
        push!(existing_figures, filename)
        cp(figure_path, joinpath(destination_folder, filename); force=true)
        new_text = replace(new_text, unique_text=>filename)
    end

    destination_filepath = joinpath(destination_folder, splitpath(root_file)[end])
    @info "Writing complete paper to $destination_filepath"
    open(destination_filepath, "w") do io
        println(io, new_text)
    end

    nothing
end

function check_circular_references(root_file)
    # TODO: Add checking of circular references
    has_circular_refs = false
    if has_circular_refs
        @error "Could not create folder as the references are circular."
    end

    nothing
end

function parse_file(file, directory)
    lines = readlines(joinpath(directory, file))

    figure_replacements = Dict{String, String}() # uuid -> filepath
    for (i, line) in enumerate(lines)
        figure_match = match(r"\\includegraphics(?:\[.*\])?\{([^\}\{]*)\}", line)
        
        if !isnothing(figure_match)
            figure_filepath = figure_match.captures[begin]
            figure_uuid = string(uuid4())
            figure_replacements[figure_uuid] = figure_filepath
            line = replace(line, figure_filepath=>figure_uuid)
        end

        input_match = match(r"\\input\{([^\}\{]*)\}", line)
        if !isnothing(input_match)
            input_filepath = input_match.captures[begin]
            input_text = input_match.match
            if !endswith(input_filepath, ".tex")
                input_filepath = input_filepath * ".tex"
            end
            replacement_text, nested_figure_replacements = parse_file(input_filepath, directory)
            merge!(figure_replacements, nested_figure_replacements)
            line = replace(line, input_text=>replacement_text)
        end
        include_match = match(r"\\include\{([^\}\{]*)\}", line)
        if !isnothing(include_match)
            include_filepath = include_match.captures[begin]
            include_text = include_match.match
            if !endswith(include_filepath, ".tex")
                include_filepath = include_filepath * ".tex"
            end
            replacement_text, nested_figure_replacements = parse_file(include_filepath, directory)
            merge!(figure_replacements, nested_figure_replacements)
            line = replace(line, include_text=>"\\clearpage\n$replacement_text")
        end

        lines[i] = line # update in the original lines
    end

    return join(lines, "\n"), figure_replacements

end

function compile_paper(directory, root_file)
    # Works on windows I think
    compile_buffer = IOBuffer()
    compile_cmd = Cmd(`latexmk -f -pdf -interaction=nonstopmode $root_file`, dir=directory)
    run(pipeline(compile_cmd; stdout=compile_buffer))
    bbl_file = first([joinpath(directory, f) for f in readdir(directory) if splitext(f)[end] == ".bbl"])
    temp_bbl_file = bbl_file * ".tex"
    mv(bbl_file, temp_bbl_file; force=true)
    clean_cmd = Cmd(`latexmk -c`, dir=directory)
    compile_buffer.writable = true
    run(pipeline(clean_cmd; stdout=compile_buffer))
    mv(temp_bbl_file, bbl_file; force=true)
    compilation_log_path = joinpath(directory, "latexmk_compilation_log.txt")
    @info "Writing compilation logs to $compilation_log_path"
    open(compilation_log_path, "w") do io
        write(io, String(take!(compile_buffer)))
    end
    nothing
end


function package(directory=pwd(); submission_dir=joinpath(directory, "submission"), force_overwrite=false)
    root_files = find_root_files(directory)
    if length(root_files) > 1
        @error "Detected too many root files, please ensure there is only one file with `\\documentclass` and `\\begin{document}`"
    elseif length(root_files) == 0
        @error "Did not detect a root file in $directory"
    end
    root_file = root_files[begin]
    check_circular_references(root_file)
    @info "Packaging files starting at $root_file in $directory"
    package_root(root_file, directory, submission_dir, force_overwrite)
    for bib_file in [f for f in readdir(directory) if (splitext(f)[end] == ".bib") && (!contains(f, "Notes.bib"))]
        @info "Copying $bib_file"
        cp(joinpath(directory, bib_file), joinpath(submission_dir, bib_file); force=true)
    end
    @info "Compiling extracted package..."
    compile_paper(submission_dir, root_file)
    @info "Finished packaging and compiling!"
    
    @info "Output available at $submission_dir."
end

export package

end
