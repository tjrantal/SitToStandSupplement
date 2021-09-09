function angle = getPostureAngle(data,refXYZ)
    currentOrientation =  [data.x, data.y, data.z];
    onepernorm = 1./sqrt(sum(currentOrientation.^2,2));
    normalisedOrientation = bsxfun(@times,currentOrientation,onepernorm);
    refXYZ = repmat(refXYZ,[size(normalisedOrientation,1),1]);
    angle = acos(dot(normalisedOrientation,refXYZ,2));
end