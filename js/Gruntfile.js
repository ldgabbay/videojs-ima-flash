module.exports = function( grunt ) {
    "use strict";

    var library_name = "daxee";
    var filelist = [].concat(["wrap/intro.js"], grunt.file.readJSON("build/filelist.json"), ["wrap/outro.js"]);

    console.log(filelist);

    grunt.initConfig({
        jshint: {
            main: {
                src: [ "src/**/*.js" ],
                options: {
                    jshintrc: true
                }
            },
            framework: {
                src: [ "Gruntfile.js" ],
                options: {
                    jshintrc: true
                }
            }
        },
        jsonlint: {
            framework: {
                src: [ "package.json" ]
            }
        },
        jscs: {
            main: {
                src: "src/**/*.js"
            },
            framework: {
                src: "Gruntfile.js"
            }
        },
        concat: {
            main: {
                src: filelist,
                dest: "build/dist/"+library_name+".js"
            }
        },
        uglify: {
            main: {
                src: [ "build/dist/"+library_name+".js" ],
                dest: "build/dist/"+library_name+".min.js",
                options: {
                    preserveComments: false,
                    sourceMap: "build/dist/"+library_name+".min.map",
                    sourceMappingURL: library_name+".min.map",
                    report: "min",
                    beautify: {
                        ascii_only: true
                    },
                    banner: "/* (c) 2015 Daxee */",
                    compress: {
                        hoist_funs: false,
                        loops: false,
                        unused: false
                    }
                }
            }
        }
    });

    grunt.loadNpmTasks("grunt-contrib-concat");
    grunt.loadNpmTasks("grunt-contrib-jshint");
    grunt.loadNpmTasks("grunt-contrib-uglify");
    grunt.loadNpmTasks("grunt-jscs");
    grunt.loadNpmTasks("grunt-jsonlint");

    grunt.registerTask("lint", ["jshint:main", "jscs:main"]);
    grunt.registerTask("compile", ["concat:main", "uglify:main"]);
    grunt.registerTask("default", ["lint", "compile"]);
};
