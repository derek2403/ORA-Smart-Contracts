// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IAIOracle.sol";
import "./AIOracleCallbackReceiver.sol";

contract Dashboard is AIOracleCallbackReceiver {

    event storeRatingEvaluation(
        uint256 requestId,
        uint256 modelId,
        string[] reviews,
        string output,
        bytes callbackData
    );

    event storeRatingEvaluationRequest(
        uint256 requestId,
        address sender, 
        uint256 modelId,
        string[] reviews
    );

    struct AIOracleRequest {
        address sender;
        uint256 modelId;
        bytes input;
        bytes output;
    }

    address public owner;

    mapping(uint256 => AIOracleRequest) public requests;
    mapping(uint256 => uint64) public callbackGasLimit;
    mapping(uint256 => mapping(string => string)) public storeRatings;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(IAIOracle _aiOracle) AIOracleCallbackReceiver(_aiOracle) {
        owner = msg.sender;
        callbackGasLimit[11] = 5_000_000; // Llama model for store rating evaluations
    }

    function getStoreRating(uint256 modelId, string calldata reviewList) external view returns (string memory) {
        return storeRatings[modelId][reviewList];
    }

    function aiOracleCallback(uint256 requestId, bytes calldata output, bytes calldata callbackData) external override onlyAIOracleCallback() {
        AIOracleRequest storage request = requests[requestId];
        require(request.sender != address(0), "request does not exist");
        request.output = output;

        string memory reviewList = string(request.input);
        storeRatings[request.modelId][reviewList] = string(output);

        emit storeRatingEvaluation(requestId, request.modelId, getReviewsArray(reviewList), string(output), callbackData);
    }

    function estimateFee(uint256 modelId) public view returns (uint256) {
        return aiOracle.estimateFee(modelId, callbackGasLimit[modelId]);
    }

    function evaluateStoreRating(
        uint256 modelId,
        string[] calldata reviews
    ) payable external {
        require(msg.value >= aiOracle.estimateFee(modelId, callbackGasLimit[modelId]), "Insufficient fee");

        // Concatenate all reviews into a single string
        string memory concatenatedReviews = concatenateReviews(reviews);

        // Updated instruction for the AI to return ratings for food, service, and price
        string memory promptInstruction = string(abi.encodePacked(
            "Read the following customer reviews: '",
            concatenatedReviews,
            "'. Based on these reviews, provide ratings out of 5 for food, service, and price. Output the ratings in the following format without any additional text: 'food:X/5,service:Y/5,price:Z/5' where X, Y, and Z are the respective ratings, the rating must be range of 0-5, dont put N/A or others"
        ));

        bytes memory input = bytes(promptInstruction);
        bytes memory callbackData = bytes("");
        address callbackAddress = address(this);

        try aiOracle.requestCallback{value: msg.value}(
            modelId, input, callbackAddress, callbackGasLimit[modelId], callbackData
        ) returns (uint256 requestId) {
            AIOracleRequest storage request = requests[requestId];
            request.input = input;
            request.sender = msg.sender;
            request.modelId = modelId;

            emit storeRatingEvaluationRequest(requestId, msg.sender, modelId, reviews);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("AIOracle request failed: ", reason)));
        } catch (bytes memory lowLevelData) {
            revert("AIOracle request failed with unknown error");
        }
    }

    function concatenateReviews(string[] memory reviews) internal pure returns (string memory) {
        string memory concatenatedReviews = "";
        for (uint256 i = 0; i < reviews.length; i++) {
            concatenatedReviews = string(abi.encodePacked(concatenatedReviews, reviews[i], " "));
        }
        return concatenatedReviews;
    }

    function getReviewsArray(string memory reviewList) internal pure returns (string[] memory) {
        // Create a fixed-size array with one element
        string[] memory reviews = new string[](1);
        reviews[0] = reviewList; // Store the entire reviewList as a single element in the array
        return reviews;
    }
}