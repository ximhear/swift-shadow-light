import simd

typealias float3 = simd_float3
struct Ray {
    var origin: simd_float3
    var direction: simd_float3
};

struct Sphere {
    var center: simd_float3
    var radius: Float
};

struct Plane {
    var yCoord: Float
};

struct Light {
    var position: simd_float3
};

func unionOp(_ d0: Float, _ d1: Float) -> Float {
    return min(d0, d1);
}

func differenceOp(_ d0: Float, _ d1: Float) -> Float {
    return max(d0, -d1);
}

func distToSphere(_ ray: Ray, _ s: Sphere) -> Float {
    return length(ray.origin - s.center) - s.radius;
}

func distToPlane(_ ray: Ray, _ plane: Plane) -> Float {
    return ray.origin.y - plane.yCoord;
}

func distToScene(_ r: Ray) -> Float {
    let p = Plane(yCoord: 0.0);
    let d2p = distToPlane(r, p);
//    var s1 = Sphere(center: simd_float3(2.0), radius: 2.0)
    let s2 = Sphere(center: simd_float3(0.0, 2.0, 0.0), radius: 2.0)
//    var s3 = Sphere(center: simd_float3(0.0, 4.0, 0.0), radius: 3.9)
    var repeatRay = r;
    repeatRay.origin = fract(r.origin / 4.0) * 4.0;
//    var d2s1 = distToSphere(repeatRay, s1);
    let d2s2 = distToSphere(r, s2);
//    var d2s3 = distToSphere(r, s3);
//    var dist = differenceOp(d2s2, d2s3);
//    dist = differenceOp(dist, d2s1);
//    dist = unionOp(d2p, dist);
    let dist = unionOp(d2p, d2s2);
    return dist;
}

func getNormal(_ ray: Ray) -> simd_float3 {
    let eps = simd_float2(0.001, 0.0);
    let n = simd_float3(
        distToScene(Ray(origin: simd_float3(ray.origin.x + eps.x, ray.origin.y + eps.y, ray.origin.z + eps.y), direction: ray.direction))
            - distToScene(Ray(origin:simd_float3(ray.origin.x - eps.x, ray.origin.y - eps.y, ray.origin.z - eps.y), direction: ray.direction)),
        distToScene(Ray(origin: simd_float3(ray.origin.x + eps.y, ray.origin.y + eps.x, ray.origin.z + eps.y), direction: ray.direction))
            - distToScene(Ray(origin:simd_float3(ray.origin.x - eps.y, ray.origin.y - eps.x, ray.origin.z - eps.y), direction: ray.direction)),
        distToScene(Ray(origin: simd_float3(ray.origin.x + eps.y, ray.origin.y + eps.y, ray.origin.z + eps.x), direction: ray.direction))
            - distToScene(Ray(origin:simd_float3(ray.origin.x - eps.y, ray.origin.y - eps.y, ray.origin.z - eps.x), direction: ray.direction)))
    return normalize(n);
}

func lighting(_ ray: Ray, _ normal: simd_float3, _ light: Light) -> Float {
    let lightRay: simd_float3 = normalize(light.position - ray.origin);
    let diffuse = max(0.0, dot(normal, lightRay));
    let reflectedRay = reflect(ray.direction, n: normal);
    var specular = max(0.0, dot(reflectedRay, lightRay));
    specular = pow(specular, 200.0);
    return diffuse + specular;
}

func shadow(_ ray: Ray, _ k: Float, _ l: Light) -> Float {
    var lightDir = l.position - ray.origin;
    let lightDist = length(lightDir);
    lightDir = normalize(lightDir);
    var light: Float = 1.0;
    var eps: Float = 0.1;
    var distAlongRay = eps * 2.0;
    for _ in 0..<100 {
        let lightRay = Ray(origin: ray.origin + lightDir * distAlongRay, direction: lightDir);
        let dist = distToScene(lightRay);
        light = min(light, 1.0 - (eps - dist) / eps);
        distAlongRay += dist * 0.5;
        eps += dist * k;
        if (distAlongRay > lightDist) { break; }
    }
    return max(light, 0.0);
}

func compute(x: Float, y: Float, z: Float, time: Float) {
//    var uv = simd_float2(x, y)
//    uv = uv * 2.0 - 1.0;
//    uv.y = -uv.y;
    var col = simd_float3(repeating: 0.0);
    
    var ray = Ray(origin: float3(0.0, 2.0, -4), direction: normalize(float3(x, y, z)));
    print("ray origin : \(ray.origin)")
    print("ray direction : \(ray.direction)")

    var hit = false;
    for i in 0..<200 {
        print("raymarching origin[\(i)] : \(ray.origin)")
        let dist = distToScene(ray);
        print("dist : \(dist)")
        if (dist < 0.001) {
            print("hit")
            hit = true;
            break;
        }
        ray.origin += ray.direction * dist;
    }
    col = float3(repeating: 1.0);
    if (!hit) {
        col = simd_float3(0.8, 0.5, 0.5);
    } else {
        let n = getNormal(ray);
        let light = Light(position: simd_float3(0, 6.0, 8.0));
//        var light = Light(position: simd_float3(sin(time) * 10.0, 5.0, cos(time) * 10.0));
        let l = lighting(ray, n, light);
        let s = shadow(ray, 0.3, light);
        col = col * l * s;
        
        print("ray origin : \(ray.origin)")
        print("ray direction : \(ray.direction)")
        print("normal : \(n)")
        print("light position: \(light.position)")
        print("lighting : \(l)")
        print("shadow : \(s)")
    }
//    var light2 = Light(position: simd_float3(0.0, 5.0, -15.0));
//    var lightRay = normalize(light2.position - ray.origin);
//    var fl = max(0.0, dot(getNormal(ray), lightRay) / 2.0);
//    col = col + fl;
    print("final color : \(col)")
}

compute(x: 0, y: sqrt(3), z: 3, time: 0)
