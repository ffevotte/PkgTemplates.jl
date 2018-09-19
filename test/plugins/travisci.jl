user = gitconfig["github.user"]
t = Template(; user=me)
temp_dir = mktempdir()
pkg_dir = joinpath(temp_dir, test_pkg)

@testset "TravisCI" begin
    @testset "Plugin creation" begin
        p = TravisCI()
        @test isempty(p.gitignore)
        @test p.src == joinpath(PkgTemplates.DEFAULTS_DIR, "travis.yml")
        @test p.dest == ".travis.yml"
        @test p.badges == [
            Badge(
                "Build Status",
                "https://travis-ci.org/{{USER}}/{{PKGNAME}}.jl.svg?branch=master",
                "https://travis-ci.org/{{USER}}/{{PKGNAME}}.jl",
            ),
        ]
        @test isempty(p.view)
        p = TravisCI(; config_file=nothing)
        @test p.src === nothing
        p = TravisCI(; config_file=test_file)
        @test p.src == test_file
        @test_throws ArgumentError TravisCI(; config_file=fake_path)
    end

    @testset "Badge generation" begin
        p = TravisCI()
        @test badges(p, user, test_pkg) == ["[![Build Status](https://travis-ci.org/$user/$test_pkg.jl.svg?branch=master)](https://travis-ci.org/$user/$test_pkg.jl)"]
    end

    @testset "File generation" begin
        p = TravisCI()
        @test gen_plugin(p, t, temp_dir, test_pkg) == [".travis.yml"]
        @test isfile(joinpath(pkg_dir, ".travis.yml"))
        travis = read(joinpath(pkg_dir, ".travis.yml"), String)
        @test !occursin("after_success", travis)
        @test !occursin("Codecov.submit", travis)
        @test !occursin("Coveralls.submit", travis)
        @test !occursin("Pkg.add(\"Documenter\")", travis)
        rm(joinpath(pkg_dir, ".travis.yml"))
        t.plugins[CodeCov] = CodeCov()
        gen_plugin(p, t, temp_dir, test_pkg)
        delete!(t.plugins, CodeCov)
        travis = read(joinpath(pkg_dir, ".travis.yml"), String)
        @test occursin("after_success", travis)
        @test occursin("Codecov.submit", travis)
        @test !occursin("Coveralls.submit", travis)
        @test !occursin("Pkg.add(\"Documenter\")", travis)
        rm(joinpath(pkg_dir, ".travis.yml"))
        t.plugins[Coveralls] = Coveralls()
        gen_plugin(p, t, temp_dir, test_pkg)
        delete!(t.plugins, Coveralls)
        travis = read(joinpath(pkg_dir, ".travis.yml"), String)
        @test occursin("after_success", travis)
        @test occursin("Coveralls.submit", travis)
        @test !occursin("Codecov.submit", travis)
        @test !occursin("Pkg.add(\"Documenter\")", travis)
        rm(joinpath(pkg_dir, ".travis.yml"))
        t.plugins[GitHubPages] = GitHubPages()
        gen_plugin(p, t, temp_dir, test_pkg)
        delete!(t.plugins, GitHubPages)
        travis = read(joinpath(pkg_dir, ".travis.yml"), String)
        @test occursin("after_success", travis)
        @test occursin("Pkg.add(\"Documenter\")", travis)
        @test !occursin("Codecov.submit", travis)
        @test !occursin("Coveralls.submit", travis)
        rm(joinpath(pkg_dir, ".travis.yml"))
        p = TravisCI(; config_file=nothing)
        @test isempty(gen_plugin(p, t, temp_dir, test_pkg))
        @test !isfile(joinpath(pkg_dir, ".travis.yml"))
    end
end

rm(temp_dir; recursive=true)
