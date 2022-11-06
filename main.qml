import QtQuick 2.2 as QQ2
import Qt3D.Core 2.0
import Qt3D.Render 2.0
import Qt3D.Input 2.0
import Qt3D.Extras 2.0

Entity {
    Camera {
        id: camera
        projectionType: CameraLens.PerspectiveProjection
        fieldOfView: 45
        aspectRatio: 16/9
        nearPlane : 0.1
        farPlane : 1000.0
        position: Qt.vector3d( 0.0, 0.0, -40.0 )
        upVector: Qt.vector3d( 0.0, 1.0, 0.0 )
        viewCenter: Qt.vector3d( 0.0, 0.0, 0.0 )
    }

    OrbitCameraController {
        camera: camera
    }

    components: [
        RenderSettings {
            activeFrameGraph: RenderSurfaceSelector {
                id: surfaceSelector
                Viewport {
                    CameraSelector {
                        camera: camera
                        FrustumCulling {
                            TechniqueFilter {
                                matchAll: [
                                    FilterKey { name: "renderingStyle"; value: "forward" }
                                ]
                                ClearBuffers {
                                    clearColor: Qt.rgba(0.1, 0.2, 0.3)
                                    buffers: ClearBuffers.ColorDepthStencilBuffer
                                }
                            }
                            TechniqueFilter {
                                matchAll: [
                                    FilterKey { name: "renderingStyle"; value: "outline" }
                                ]
                                RenderPassFilter {
                                    matchAny: [
                                        FilterKey {
                                            name: "pass"; value: "geometry"
                                        }
                                    ]
                                    ClearBuffers {
                                        buffers: ClearBuffers.ColorDepthStencilBuffer
                                        RenderTargetSelector {
                                            target: RenderTarget {
                                                attachments : [
                                                    RenderTargetOutput {
                                                        objectName : "color"
                                                        attachmentPoint : RenderTargetOutput.Color0
                                                        texture : Texture2D {
                                                            id : colorAttachment
                                                            width : surfaceSelector.surface ? surfaceSelector.surface.width : 512
                                                            height : surfaceSelector.surface ? surfaceSelector.surface.height : 512
                                                            format : Texture.RGBA32F
                                                        }
                                                    }
                                                ]
                                            }
                                        }
                                    }
                                }
                                RenderPassFilter {
                                    parameters: [
                                        Parameter { name: "color"; value: colorAttachment },
                                        Parameter { name: "winSize"; value : Qt.size(surfaceSelector.surface ? surfaceSelector.surface.width : 512, surfaceSelector.surface ? surfaceSelector.surface.height : 512) }
                                    ]
                                    matchAny: [
                                        FilterKey {
                                            name: "pass"; value: "outline"
                                        }
                                    ]
                                }
                            }
                        }
                    }
                }
            }
        },
        InputSettings { }
    ]

    PhongMaterial {
        id: material
    }

    Material {
        id: outlineMaterial

        effect: Effect {
            techniques: [
                Technique {
                    graphicsApiFilter {
                        api: GraphicsApiFilter.OpenGL
                        majorVersion: 3
                        minorVersion: 1
                        profile: GraphicsApiFilter.CoreProfile
                    }

                    filterKeys: [
                        FilterKey { name: "renderingStyle"; value: "outline" }
                    ]
                    renderPasses: [
                        RenderPass {
                            filterKeys: [
                                FilterKey { name: "pass"; value: "geometry" }
                            ]
                            shaderProgram: ShaderProgram {
                                vertexShaderCode: "
#version 150 core

in vec3 vertexPosition;

uniform mat4 modelViewProjection;

void main()
{
    gl_Position = modelViewProjection * vec4( vertexPosition, 1.0 );
}
"

                                fragmentShaderCode: "
#version 150 core

out vec4 fragColor;

void main()
{
    fragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}
"
                            }
                        }
                    ]
                }
            ]
        }
    }

    CuboidMesh {
        id: sphereMesh
    }

    Transform {
        id: sphereTransform
    }

    Transform {
        id: sphereTransform2
        // TODO workaround because the transform cannot be shared
        matrix: sphereTransform.matrix
    }

    Entity {
        id: sphereEntity
        components: [ sphereMesh, material, sphereTransform ]
    }

    Entity {
        id: sphereOutlineEntity
        components: [ sphereMesh, outlineMaterial, sphereTransform2 ]
    }

    Entity {
        id: outlineQuad
        components: [
            PlaneMesh {
                width: 2.0
                height: 2.0
                meshResolution: Qt.size(2, 2)
            },
            Transform {
                rotation: fromAxisAndAngle(Qt.vector3d(1, 0, 0), 90)
            },
            Material {
                effect: Effect {
                    techniques: [
                        Technique {
                            filterKeys: [
                                FilterKey { name: "renderingStyle"; value: "outline" }
                            ]
                            graphicsApiFilter {
                                api: GraphicsApiFilter.OpenGL
                                profile: GraphicsApiFilter.CoreProfile
                                majorVersion: 3
                                minorVersion: 1
                            }
                            renderPasses : RenderPass {
                                filterKeys : FilterKey { name : "pass"; value : "outline" }
                                shaderProgram : ShaderProgram {
                                    vertexShaderCode: "
#version 150

in vec4 vertexPosition;
uniform mat4 modelMatrix;

void main()
{
    gl_Position = modelMatrix * vertexPosition;
}
"

                                    fragmentShaderCode: "
#version 150

uniform sampler2D color;
uniform vec2 winSize;

out vec4 fragColor;

void main()
{

    int lineWidth = 5;

    vec2 texCoord = gl_FragCoord.xy / winSize;
    vec2 texCoordUp = (gl_FragCoord.xy + vec2(0, lineWidth)) / winSize;
    vec2 texCoordDown = (gl_FragCoord.xy + vec2(0, -lineWidth)) / winSize;
    vec2 texCoordRight = (gl_FragCoord.xy + vec2(lineWidth, 0)) / winSize;
    vec2 texCoordLeft = (gl_FragCoord.xy + vec2(-lineWidth, 0)) / winSize;

    vec4 col = texture(color, texCoord);
    vec4 colUp = texture(color, texCoordUp);
    vec4 colDown = texture(color, texCoordDown);
    vec4 colRight = texture(color, texCoordRight);
    vec4 colLeft = texture(color, texCoordLeft);

    if ((colUp == colDown && colRight == colLeft) || col.a == 0.0)
        discard;

    fragColor = col;
}
"
                                }
                            }
                        }]
                }
            }

        ]
    }
}
