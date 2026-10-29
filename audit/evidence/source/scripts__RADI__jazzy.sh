1: #!/bin/bash
2: 
3: # Default branch if not specified
4: ROBOTICS_ACADEMY="humble-devel"
5: ROBOTICS_INFRASTRUCTURE="humble-devel"
6: RAM="humble-devel"
7: ROS_DISTRO="jazzy"
8: IMAGE_TAG="test"
9: FORCE_BUILD=false
10: FORCE_BUILD_NO_CACHE=false
11: 
12: # Default GitHub owners
13: ACADEMY_OWNER="JdeRobot"
14: INFRA_OWNER="JdeRobot"
15: 
16: Help()
17: {
18:    echo "Syntax: build.sh [options]"
19:    echo "Options:"
20:    echo "  -h                           Print this Help."
21:    echo "  -f                           Force creation of the base image. If omitted, the base image is created only if it doesn't exist."
22:    echo "  -F                           Force creation of the base image without using docker cache."
23:    echo "  -a, --academy       <value>  Branch of RoboticsAcademy.               Default: humble-devel"
24:    echo "  -i, --infra         <value>  Branch of RoboticsInfrastructure.        Default: humble-devel"
25:    echo "  -m, --ram           <value>  Branch of RoboticsApplicationManager.    Default: humble-devel"
26:    echo "  -r, --ros           <value>  ROS Distro (jazzy).                     Default: jazzy"
27:    echo "  -t, --tag           <value>  Tag name of the image.                   Default: test"
28:    echo "  --academy-owner     <value>  GitHub owner for RoboticsAcademy.        Default: JdeRobot"
29:    echo "  --infra-owner       <value>  GitHub owner for RoboticsInfrastructure. Default: JdeRobot"
30:    echo
31:    echo "Example:"
32:    echo "   ./build.sh -t my_image"
33:    echo "   ./build.sh --infra-owner <github-user> -i <infra-fork-branch> --tag my_image"
34:    echo
35: }
36: 
37: while [[ $# -gt 0 ]]; do
38:     case "$1" in
39:         -a | --academy)
40:             ROBOTICS_ACADEMY="$2"
41:             shift 2
42:             ;;
43:         -i | --infra)
44:             ROBOTICS_INFRASTRUCTURE="$2"
45:             shift 2
46:             ;;
47:         -m | --ram)
48:             RAM="$2"
49:             shift 2
50:             ;;
51:         -r | --ros)
52:             ROS_DISTRO="$2"
53:             shift 2
54:             ;;
55:         -t | --tag)
56:             IMAGE_TAG="$2"
57:             shift 2
58:             ;;
59:         --academy-owner)
60:             ACADEMY_OWNER="$2"
61:             shift 2
62:             ;;
63:         --infra-owner)
64:             INFRA_OWNER="$2"
65:             shift 2
66:             ;;
67:         -f | --force)
68:             FORCE_BUILD=true
69:             shift
70:             ;;
71:         -F | --force-no-cache)
72:             FORCE_BUILD_NO_CACHE=true
73:             shift
74:             ;;
75:         -h | --help)
76:             echo "Generates RoboticsAcademy RoboticsBackend image"
77:             echo
78:             Help
79:             exit 0
80:             ;;
81:         *)
82:             echo "Invalid Option: $1"
83:             Help
84:             exit 1
85:             ;;
86:    esac
87: done
88: 
89: echo "ROBOTICS_ACADEMY:-------------:$ROBOTICS_ACADEMY (Owner: $ACADEMY_OWNER)"
90: echo "ROBOTICS_INFRASTRUCTURE:------:$ROBOTICS_INFRASTRUCTURE (Owner: $INFRA_OWNER)"
91: echo "RAM:--------------------------:$RAM"
92: echo "ROS_DISTRO:-------------------:$ROS_DISTRO"
93: echo "IMAGE_TAG:--------------------:$IMAGE_TAG"
94: echo
95: 
96: if [[ $ROS_DISTRO == "jazzy" ]]; then
97:     DOCKERFILE_BASE="Dockerfile.dependencies_jazzy"
98:     DOCKERFILE="Dockerfile.humble"
99: else
100:     echo "Error: Unknown ROS_DISTRO ($ROS_DISTRO). Please set it to 'humble'."
101:     exit 1
102: fi
103: 
104: if $FORCE_BUILD_NO_CACHE; then
105:   NO_CACHE="--no-cache"
106: else
107:   NO_CACHE=""
108: fi
109: 
110: if $FORCE_BUILD_NO_CACHE || $FORCE_BUILD || [[ "$(docker images -q jderobot/robotics-applications:dependencies-$ROS_DISTRO 2> /dev/null)" == "" ]]; then
111:   echo "===================== BUILDING $ROS_DISTRO BASE IMAGE ====================="
112:   echo "Building base using $DOCKERFILE_BASE for ROS $ROS_DISTRO"
113:   docker build $NO_CACHE -f $DOCKERFILE_BASE \
114:     --build-arg TARGETARCH=$(uname -m | sed 's/x86_64/amd64/;s/arm64/arm64/') \
115:     -t jderobot/robotics-applications:dependencies-$ROS_DISTRO .
116: fi
117: 
118: if [ $? -eq 0 ]; then
119:     echo "Docker Base Image Build Successful"
120: else
121:     echo "Docker Base Image Build FAILED...exiting"
122:     exit
123: fi
124: 
125: echo "===================== BUILDING $ROS_DISTRO RoboticsBackend ====================="
126: echo "Building RoboticsBackend using $DOCKERFILE for ROS $ROS_DISTRO"
127: 
128: docker build --no-cache -f $DOCKERFILE \
129:   --build-arg ROBOTICS_ACADEMY=$ROBOTICS_ACADEMY \
130:   --build-arg ROBOTICS_INFRASTRUCTURE=$ROBOTICS_INFRASTRUCTURE \
131:   --build-arg RAM=$RAM \
132:   --build-arg ROS_DISTRO=$ROS_DISTRO \
133:   --build-arg IMAGE_TAG=$IMAGE_TAG \
134:   --build-arg ACADEMY_OWNER=$ACADEMY_OWNER \
135:   --build-arg INFRA_OWNER=$INFRA_OWNER \
136:   -t jderobot/robotics-academy:$IMAGE_TAG .
