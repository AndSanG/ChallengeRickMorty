//
//  RickAndMortyAPIEndToEndTests.swift
//  RickAndMortyAPIEndToEndTests
//
//  Created by Andres Sanchez on 6/3/26.
//

import Testing
import Foundation
@testable import RickAndMortyDomain

// These tests hit the real Rick and Morty API.
// Kept in a separate target so they never run alongside fast unit tests.
// Run manually to verify live integration.

@Suite(.serialized) struct RickAndMortyAPIEndToEndTests {

    private let loader = RemoteCharacterLoader(
        baseURL: URL(string: "https://rickandmortyapi.com/api")!,
        client: URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
    )

    @Test func load_page1_deliversNonEmptyResults() async {
        let page = await loadPage(CharacterQuery(page: 1))
        #expect((page?.results.count ?? 0) > 0, "Expected non-empty results on page 1")
    }

    @Test func load_page1_deliversExpectedFirstCharacter() async {
        let page = await loadPage(CharacterQuery(page: 1))
        let first = page?.results.first
        #expect(first?.id == 1)
        #expect(first?.name == "Rick Sanchez")
        #expect(first?.status == .alive)
    }

    @Test func load_withNameFilter_deliversOnlyMatchingResults() async {
        let page = await loadPage(CharacterQuery(page: 1, name: "rick"))
        let allMatch = page?.results.allSatisfy { $0.name.lowercased().contains("rick") } ?? false
        #expect(allMatch, "Expected all results to contain 'rick' in name")
    }

    @Test func load_withStatusFilter_deliversOnlyAliveCharacters() async {
        let page = await loadPage(CharacterQuery(page: 1, status: .alive))
        let allAlive = page?.results.allSatisfy { $0.status == .alive } ?? false
        #expect(allAlive, "Expected all results to have status .alive")
    }

    // MARK: - Helpers

    private func loadPage(_ query: CharacterQuery) async -> CharactersPage? {
        await withCheckedContinuation { continuation in
            loader.load(query: query) { result in
                continuation.resume(returning: try? result.get())
            }
        }
    }
}
