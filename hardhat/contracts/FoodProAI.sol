// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IAIOracle.sol";
import "./AIOracleCallbackReceiver.sol";

contract FoodProAI is AIOracleCallbackReceiver {

    event foodRecommendation(
        uint256 requestId,
        uint256 modelId,
        string input,
        string output,
        bytes callbackData
    );

    event foodPromptRequest(
        uint256 requestId,
        address sender, 
        uint256 modelId,
        string prompt
    );

    struct AIOracleRequest {
        address sender;
        uint256 modelId;
        bytes input;
        bytes output;
    }

    struct FoodPreferences {
        string cuisineType;
        string mealType;
        string dietaryRestriction;
        string mood;
    }

    address public owner;

    mapping(uint256 => AIOracleRequest) public requests;
    mapping(uint256 => uint64) public callbackGasLimit;
    mapping(uint256 => mapping(string => string)) public foodRecommendations;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(IAIOracle _aiOracle) AIOracleCallbackReceiver(_aiOracle) {
        owner = msg.sender;
        callbackGasLimit[11] = 5_000_000; // Llama model for food recommendations
    }

    function getFoodRecommendation(uint256 modelId, string calldata prompt) external view returns (string memory) {
        return foodRecommendations[modelId][prompt];
    }

    function aiOracleCallback(uint256 requestId, bytes calldata output, bytes calldata callbackData) external override onlyAIOracleCallback() {
        AIOracleRequest storage request = requests[requestId];
        require(request.sender != address(0), "request does not exist");
        request.output = output;
        foodRecommendations[request.modelId][string(request.input)] = string(output);
        emit foodRecommendation(requestId, request.modelId, string(request.input), string(output), callbackData);
    }

    function estimateFee(uint256 modelId) public view returns (uint256) {
        return aiOracle.estimateFee(modelId, callbackGasLimit[modelId]);
    }

    function recommendFood(
        uint256 modelId,
        FoodPreferences calldata preferences
    ) payable external {
        require(msg.value >= aiOracle.estimateFee(modelId, callbackGasLimit[modelId]), "Insufficient fee");

        string memory foodPrompt = string(abi.encodePacked(
            "List 6 food recommendations for ", preferences.mealType,
            " cuisine: ", preferences.cuisineType, 
            ". Dietary restriction: ", preferences.dietaryRestriction, 
            ". Mood: ", preferences.mood, 
            ". Format: 'Dish 1 | Dish 2 | Dish 3 | Dish 4 | Dish 5 | Dish 6'"
        ));

        bytes memory input = bytes(foodPrompt);
        bytes memory callbackData = bytes("");
        address callbackAddress = address(this);

        try aiOracle.requestCallback{value: msg.value}(
            modelId, input, callbackAddress, callbackGasLimit[modelId], callbackData
        ) returns (uint256 requestId) {
            AIOracleRequest storage request = requests[requestId];
            request.input = input;
            request.sender = msg.sender;
            request.modelId = modelId;

            emit foodPromptRequest(requestId, msg.sender, modelId, foodPrompt);
        } catch Error(string memory reason) {
            revert(string(abi.encodePacked("AIOracle request failed: ", reason)));
        } catch (bytes memory lowLevelData) {
            revert("AIOracle request failed with unknown error");
        }
    }
}