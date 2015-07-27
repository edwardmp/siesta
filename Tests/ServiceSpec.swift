//
//  ServiceTests.swift
//  ServiceTests
//
//  Created by Paul on 2015/6/14.
//  Copyright © 2015 Bust Out Solutions. All rights reserved.
//

import Siesta
import Quick
import Nimble

class ServiceSpec: QuickSpec
    {
    override func spec()
        {
        let service  = specVar { Service(base: "https://zingle.frotz") }
        
        describe("init()")
            {
            it("enforces a trailing slash on baseURL")
                {
                expect("http://foo.bar")     .to(expandToBaseURL("http://foo.bar/"))
                expect("http://foo.bar/")    .to(expandToBaseURL("http://foo.bar/"))
                expect("http://foo.bar/baz") .to(expandToBaseURL("http://foo.bar/baz/"))
                expect("http://foo.bar/baz/").to(expandToBaseURL("http://foo.bar/baz/"))
                }
                
            it("preserves baseURL query parameters")
                {
                expect("http://foo.bar?you=mysunshine")     .to(expandToBaseURL("http://foo.bar/?you=mysunshine"))
                expect("http://foo.bar/?you=mysunshine")    .to(expandToBaseURL("http://foo.bar/?you=mysunshine"))
                expect("http://foo.bar/baz?you=mysunshine") .to(expandToBaseURL("http://foo.bar/baz/?you=mysunshine"))
                expect("http://foo.bar/baz/?you=mysunshine").to(expandToBaseURL("http://foo.bar/baz/?you=mysunshine"))
                }
            }
        
        describe("resource()")
            {
            it("returns a resource that belongs to this service")
                {
                expect(service().resource("/foo").service)
                    .to(equal(service()))
                }
            
            it("resolves all paths as subpaths of baseURL")
                {
                // Note that checkPathExpansion tests both with & without leading slash
                checkPathExpansion("https://foo.bar",    path:"",         expect:"https://foo.bar/")
                checkPathExpansion("https://foo.bar",    path:"baz",      expect:"https://foo.bar/baz")
                checkPathExpansion("https://foo.bar",    path:"baz/fez",  expect:"https://foo.bar/baz/fez")
                checkPathExpansion("https://foo.bar",    path:"baz/fez/", expect:"https://foo.bar/baz/fez/")
                checkPathExpansion("https://foo.bar/v1", path:"baz",      expect:"https://foo.bar/v1/baz")
                checkPathExpansion("https://foo.bar/v1", path:"baz/fez",  expect:"https://foo.bar/v1/baz/fez")
                // TODO: Should there be special handling for paths starting with "." and ".."?
                }

            it("preserves baseURL query params")
                {
                checkPathExpansion("https://foo.bar/?a=b&x=y",   path:"baz/fez/", expect:"https://foo.bar/baz/fez/?a=b&x=y")
                checkPathExpansion("https://foo.bar/v1?a=b&x=y", path:"baz",      expect:"https://foo.bar/v1/baz?a=b&x=y")
                }
            }
        
        describe("caching")
            {
            it("gives the same Resource instance for the same path")
                {
                expect(service().resource("/foo"))
                    .to(beIdenticalTo(service().resource("/foo")))
                }
            
            it("gives the same Resource instance no matter how it’s constructed")
                {
                expect(service().resource("/foo").child("oogle").child("baz").relative("../bar"))
                    .to(beIdenticalTo(service().resource("/foo/bar")))
                }
            }
        }
    }


// MARK: - Custom matchers

func expandToBaseURL(expectedURL: String) -> MatcherFunc<String>
    {
    return MatcherFunc
        {
        actual, failureMessage in

        let base = try! actual.evaluate() ?? "",
            service = Service(base: base),
            actualURL = service.baseURL?.absoluteString
        failureMessage.stringValue =
            "expected baseURL \(base.debugDescription)"
            + " to expand to \(expectedURL.debugDescription),"
            + " but got \(actualURL.debugDescription)"
        return actualURL == expectedURL
        }
    }

func expandToResourceURL(expectedURL: String) -> MatcherFunc<(String,String)>
    {
    return MatcherFunc
        {
        inputs, failureMessage in
        
        let (base, resourcePath) = try! inputs.evaluate()!,
            service = Service(base: base),
            resource = service.resource(resourcePath),
            actualURL = resource.url?.absoluteString
        failureMessage.stringValue =
            "expected base \(base.debugDescription)"
            + " and resource path \(resourcePath.debugDescription)"
            + " to expand to \(expectedURL.debugDescription),"
            + " but got \(actualURL.debugDescription)"
        return actualURL == expectedURL
        }
    }

/// Checks resourcePath with and without a leading slash.
///
func checkPathExpansion(base: String, path resourcePath: String, expect expectedExpansion: String)
    {
    for resourcePathVariant in [resourcePath, "/" + resourcePath]
        {
        expect((base, resourcePathVariant))
            .to(expandToResourceURL(expectedExpansion))
        }
    }
